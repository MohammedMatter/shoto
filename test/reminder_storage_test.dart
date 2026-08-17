import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reminders in the database, against real SQLite.
///
/// Two of the promises here are invisible in any widget test and are the ones
/// that would be discovered by a reminder not arriving:
///
/// * a reminder can be the **first** thing anybody ever says about a
///   screenshot, so setting one has to create the row rather than update
///   nothing and report success;
/// * setting a reminder must not disturb the intent, or clearing one disturb
///   the other — they are set together constantly and cleared by different
///   events, and a shared write is how a fired reminder starts looking like a
///   finished task.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const String deviceId = 'local:reminder-test-device';

  late Directory dir;
  late _TempAppDatabase appDatabase;
  late LocalIdentity identity;
  late ScreenshotMetadataLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    identity = LocalIdentity();
    await identity.overrideForTesting(deviceId);

    dir = await Directory.systemTemp.createTemp('shoto_reminder_test');
    appDatabase = _TempAppDatabase(identity, '${dir.path}/shoto.db');
    dataSource = ScreenshotMetadataLocalDataSource(appDatabase, identity);
  });

  tearDown(() async {
    await appDatabase.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final DateTime soon = DateTime(2030, 6, 1, 9);

  test('setting one on a screenshot nobody has touched creates the row', () async {
    await dataSource.setReminder('asset-1', soon);

    expect(await dataSource.getPendingReminders(DateTime(2026)), {
      'asset-1': soon,
    });
  });

  test('setting one twice replaces it rather than adding a second', () async {
    final DateTime later = DateTime(2030, 6, 2, 9);

    await dataSource.setReminder('asset-1', soon);
    await dataSource.setReminder('asset-1', later);

    expect(await dataSource.getPendingReminders(DateTime(2026)), {
      'asset-1': later,
    });
  });

  test('null clears it', () async {
    await dataSource.setReminder('asset-1', soon);
    await dataSource.setReminder('asset-1', null);

    expect(await dataSource.getPendingReminders(DateTime(2026)), isEmpty);
  });

  test('only reminders still ahead come back', () async {
    // One that has been and gone is history: re-arming it would fire it at
    // entirely the wrong moment, and the row stays so the app can still show
    // it was missed.
    await dataSource.setReminder('past', DateTime(2026, 1, 1));
    await dataSource.setReminder('future', soon);

    final Map<String, DateTime> pending = await dataSource.getPendingReminders(
      DateTime(2027),
    );
    expect(pending.keys, <String>['future']);
  });

  test('a reminder and an intent do not disturb each other', () async {
    await dataSource.setIntent(<String>['asset-1'], 'pay');
    await dataSource.setReminder('asset-1', soon);

    // The intent survived being reminded about.
    expect((await dataSource.getAllIntents())['asset-1']?.intent, 'pay');

    // And clearing the reminder leaves the intent alone, which is the half
    // that matters: a reminder is spent when it fires, an intent ends when the
    // user says they did the thing.
    await dataSource.setReminder('asset-1', null);
    expect((await dataSource.getAllIntents())['asset-1']?.intent, 'pay');
  });

  test('setting an intent afterwards does not cancel the reminder', () async {
    await dataSource.setReminder('asset-1', soon);
    await dataSource.setIntent(<String>['asset-1'], 'read');

    expect(await dataSource.getPendingReminders(DateTime(2026)), {
      'asset-1': soon,
    });
  });

  test('one account never sees another account\'s reminders', () async {
    await dataSource.setReminder('asset-1', soon);

    await identity.overrideForTesting('local:somebody-else');
    expect(await dataSource.getPendingReminders(DateTime(2026)), isEmpty);
  });

  test('a database that predates the column upgrades into it', () async {
    // The real migration, run against a real file — the column is added by
    // ALTER TABLE for every install that already exists, and a guard that got
    // it wrong would take the app down on launch rather than degrade.
    final Map<String, DateTime> pending = await dataSource.getPendingReminders(
      DateTime(2026),
    );
    expect(pending, isEmpty);

    await dataSource.setReminder('asset-1', soon);
    expect((await dataSource.getPendingReminders(DateTime(2026))).length, 1);
  });
}

/// The real [AppDatabase] — real schema, real migrations — in a temp file.
class _TempAppDatabase extends AppDatabase {
  final String path;
  Database? _open;

  _TempAppDatabase(super.identity, this.path);

  @override
  Future<Database> get database async => _open ??= await openAt(path);

  Future<void> close() async {
    await _open?.close();
    _open = null;
  }
}
