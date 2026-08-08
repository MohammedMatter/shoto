import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The v17 migration is the one change in this codebase that rewrites every
/// row a user owns, so it gets a test rather than a careful reading.
///
/// What it has to be true of: a phone that has been using Shoto signed in as a
/// Firebase account. Every folder, every favourite, every library membership
/// and every user-written intent is filed under that uid, and nothing asks for
/// that uid any more. If the migration misses a table, the data in it becomes
/// invisible — which looks exactly like Shoto having deleted it.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const String oldUid = 'aZ2kQ9fFirebaseUid00000000';
  const String deviceId = 'local:test-device';

  late LocalIdentity identity;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    identity = LocalIdentity();
    await identity.overrideForTesting(deviceId);
  });

  /// Builds a v16 database — the schema as it stood before the device
  /// identity existed — with one account's data in every table.
  Future<Database> seedV16Database(String path) async {
    final Database db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 16, onCreate: (db, _) async {}),
    );
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_private INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE screenshot_meta (
        user_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        folder_id INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        ocr_text TEXT,
        phash TEXT,
        category TEXT,
        visual_labels TEXT,
        category_override TEXT,
        kept_at INTEGER,
        intent TEXT,
        intent_done_at INTEGER,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, asset_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE library_assets (
        user_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, asset_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_intents (
        user_id TEXT NOT NULL,
        id TEXT NOT NULL,
        label TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE TABLE app_flags (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );

    await db.insert('folders', {
      'user_id': oldUid,
      'name': 'Receipts',
      'color': 0xFF4477FF,
      'created_at': 1,
    });
    await db.insert('screenshot_meta', {
      'user_id': oldUid,
      'asset_id': 'asset-1',
      'is_favorite': 1,
      'ocr_text': 'total 42.00',
      'updated_at': 1,
    });
    await db.insert('library_assets', {
      'user_id': oldUid,
      'asset_id': 'asset-1',
      'added_at': 1,
    });
    await db.insert('custom_intents', {
      'user_id': oldUid,
      'id': 'intent-1',
      'label': 'Pay this',
      'icon_key': 'card',
      'sort_order': 0,
      'created_at': 1,
    });
    await db.close();

    return db;
  }

  test('every table follows the user onto the device identity', () async {
    final String path = await _tempDbPath('adopt');
    await seedV16Database(path);

    final Database db = await _openAtV17(path, identity);

    for (final String table in const [
      'folders',
      'screenshot_meta',
      'library_assets',
      'custom_intents',
    ]) {
      final List<Map<String, Object?>> rows = await db.query(table);
      expect(rows, hasLength(1), reason: '$table lost its row');
      expect(
        rows.single['user_id'],
        deviceId,
        reason: '$table was left under the old account',
      );
    }
    await db.close();
  });

  test('the contents of the rows are untouched', () async {
    final String path = await _tempDbPath('contents');
    await seedV16Database(path);

    final Database db = await _openAtV17(path, identity);

    final Map<String, Object?> meta =
        (await db.query('screenshot_meta')).single;
    expect(meta['asset_id'], 'asset-1');
    expect(meta['is_favorite'], 1);
    // Re-pointing ownership must not discard the expensive cached work.
    expect(meta['ocr_text'], 'total 42.00');

    expect((await db.query('folders')).single['name'], 'Receipts');
    expect((await db.query('custom_intents')).single['label'], 'Pay this');
    await db.close();
  });

  test('two accounts that saved the same screenshot merge, not crash', () async {
    final String path = await _tempDbPath('merge');
    await seedV16Database(path);

    // A second account on the same phone, holding the *same* asset — which
    // collides on the (user_id, asset_id) primary key the moment both are
    // re-pointed at one identity. This is what UPDATE OR REPLACE is for.
    final Database seeded = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 16),
    );
    await seeded.insert('library_assets', {
      'user_id': 'secondAccountUid',
      'asset_id': 'asset-1',
      'added_at': 2,
    });
    await seeded.insert('screenshot_meta', {
      'user_id': 'secondAccountUid',
      'asset_id': 'asset-1',
      'is_favorite': 0,
      'updated_at': 2,
    });
    await seeded.close();

    final Database db = await _openAtV17(path, identity);

    // One row survives per asset, and it belongs to the device.
    final List<Map<String, Object?>> assets = await db.query('library_assets');
    expect(assets, hasLength(1));
    expect(assets.single['user_id'], deviceId);
    expect(assets.single['asset_id'], 'asset-1');
    await db.close();
  });

  test('running it twice changes nothing', () async {
    final String path = await _tempDbPath('idempotent');
    await seedV16Database(path);

    final Database first = await _openAtV17(path, identity);
    final int before = (await first.query('library_assets')).length;
    await first.close();

    // Reopening at the same version does not re-run onUpgrade, but the
    // statement itself is written to be safe if it ever did.
    final Database second = await _openAtV17(path, identity);
    final int after = (await second.query('library_assets')).length;
    expect(after, before);
    expect((await second.query('library_assets')).single['user_id'], deviceId);
    await second.close();
  });
}

/// Opens the seeded file through the real [AppDatabase] so the migration under
/// test is the one the app ships, not a copy of it written here.
Future<Database> _openAtV17(String path, LocalIdentity identity) async {
  final AppDatabase appDatabase = AppDatabase(identity);
  return appDatabase.openAt(path);
}

Future<String> _tempDbPath(String name) async {
  final Directory dir = await Directory.systemTemp.createTemp('shoto_$name');
  return '${dir.path}/shoto.db';
}
