import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:sqflite/sqflite.dart';

/// Single shared sqflite connection for all locally-owned organization data
/// (folders, favorites, folder assignment). The screenshots themselves are
/// never duplicated here — only references to their gallery asset ids.
///
/// Every row is scoped to a `user_id`, which as of v17 is the *device's*
/// identity ([LocalIdentity]) rather than a Firebase uid. The column stays
/// because the whole schema is keyed on it and because it still does a real
/// job — it is what a restored backup is re-pointed at — but it no longer
/// means "which account", and signing in or out never changes it. See
/// [LibraryOwnershipLocalDataSource] (which screenshots are even *in* your
/// library), [ScreenshotMetadataLocalDataSource] and [FoldersLocalDataSource]
/// for where that scoping is applied.
class AppDatabase {
  final LocalIdentity _localIdentity;

  AppDatabase(this._localIdentity);

  static const String folders = 'folders';
  static const String screenshotMeta = 'screenshot_meta';

  /// Which account each image in Shoto's album belongs to.
  ///
  /// The album on disk is one folder shared by the whole device — it has no
  /// idea accounts exist. Without this table every account signing in on the
  /// same phone saw every other account's screenshots, because "the library"
  /// was really just "the contents of Pictures/SHOTO". Membership is a
  /// decision the app makes, so it belongs here rather than on the filesystem.
  static const String libraryAssets = 'library_assets';

  /// Intents the user wrote themselves, as opposed to the ones Shoto ships.
  ///
  /// A table rather than a JSON blob in preferences because the ids in it are
  /// foreign keys in spirit — `screenshot_meta.intent` points at them — and
  /// because deleting one has to clear those references in the same
  /// transaction. Not an actual `FOREIGN KEY`, because `intent` holds built-in
  /// ids too and most of the time points at no row here at all.
  static const String customIntents = 'custom_intents';

  /// One-off internal switches (not user settings — those live in
  /// [AppPreferences]). Currently only tracks whether the images that
  /// predate [libraryAssets] have been attributed to somebody yet.
  static const String appFlags = 'app_flags';

  /// User-authored filing rules, removed in v13.
  ///
  /// The name outlives the feature because the v13 migration has to be able
  /// to say what it is dropping, and because databases created between v11
  /// and v12 still carry the table until they are upgraded.
  static const String filingRules = 'filing_rules';

  /// Set to '1' once the images that were already in Shoto's album before
  /// ownership existed have been handed to an account. Absent on a fresh
  /// install, because there is nothing there to hand over.
  static const String legacyLibraryAdoptedFlag = 'legacy_library_adopted';

  /// Stored in `screenshot_meta.category` when a screenshot has been run
  /// through the classifier but matched no category. Distinct from NULL
  /// ("never classified") so a rescan doesn't keep reprocessing screenshots
  /// that legitimately belong nowhere.
  static const String uncategorizedMarker = '_none';

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async =>
      openAt(join(await getDatabasesPath(), 'shoto.db'));

  /// Opens the database at an explicit [path], with the real schema and the
  /// real migrations.
  ///
  /// Exists so the upgrade steps can be tested against a seeded file rather
  /// than read carefully and hoped over — v17 rewrites the owner of every row
  /// a user has, and a migration that silently misses a table is
  /// indistinguishable, from the user's side, from the app losing their
  /// library. The production path above is the only caller in `lib/`.
  @visibleForTesting
  Future<Database> openAt(String path) {
    return openDatabase(
      path,
      version: 17,
      onCreate: (db, version) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Pre-launch schema change: folders/favorites gained per-user
          // scoping (user_id). Old rows weren't tied to any account, so
          // there's nothing sound to migrate them to — start clean.
          await db.execute('DROP TABLE IF EXISTS $screenshotMeta');
          await db.execute('DROP TABLE IF EXISTS $folders');
          await _createTables(db);
        }
        if (oldVersion < 3) {
          // Cached OCR text for the premium search feature — a plain
          // additive column, existing favorite/folder data is preserved.
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN ocr_text TEXT',
          );
        }
        if (oldVersion < 4) {
          // Biometric-locked private folders — additive column, defaults
          // every existing folder to not-private.
          await db.execute(
            'ALTER TABLE $folders ADD COLUMN is_private INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 5) {
          // Cached perceptual hash for duplicate detection — additive, and
          // recomputed lazily, so a null here just means "not scanned yet".
          await db.execute('ALTER TABLE $screenshotMeta ADD COLUMN phash TEXT');
        }
        if (oldVersion < 6) {
          // Smart-album category derived from the OCR text. Null means
          // "not classified yet"; a screenshot that was classified but
          // matched nothing is stored as [uncategorizedMarker].
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN category TEXT',
          );
        }
        if (oldVersion < 7) {
          // What an on-device vision model saw in the image, as JSON. Lets
          // screenshots with no readable text be classified at all, and
          // means the model never runs twice on the same picture.
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN visual_labels TEXT',
          );
        }
        if (oldVersion < 8) {
          // A category the *user* assigned by hand. Kept separate from the
          // classifier's own verdict rather than overwriting it, so a rescan
          // can never undo a correction the user made.
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN category_override TEXT',
          );
        }
        if (oldVersion < 9) {
          // Per-account library membership. Before this, signing in with a
          // second account showed that account every screenshot the first
          // one had ever saved.
          await _createLibraryAssets(db);
          await _createAppFlags(db);
        }
        if (oldVersion < 10) {
          // Attribution for everything that predates the table above.
          //
          // Runs as its own step because v9 originally seeded from *every*
          // `screenshot_meta` row, and most of those rows are not evidence of
          // ownership at all — search and the duplicate scan write one per
          // screenshot they read, purely to cache OCR text and hashes. On a
          // device where the bug had let three accounts browse the same
          // library that handed nearly every image to all three, which is the
          // very thing this release exists to stop.
          await db.delete(libraryAssets);
          await _seedLibraryOwnership(db);
        }
        // v11 created the filing_rules table and v12 added a sort_order
        // column to it. Both steps are gone rather than preserved: the
        // feature was removed in v13, so creating the table only to drop it
        // again three lines later is work with no observable effect. The
        // version numbers are *not* reused — a device that already ran v11
        // or v12 has the table, and v13 below is what removes it there.
        if (oldVersion < 13) {
          // Filing rules, removed. A user who wrote rules keeps every
          // screenshot those rules filed — the folder assignments live in
          // `screenshot_meta` and are untouched. Only the rules themselves
          // go, because nothing can read them any more.
          await db.execute('DROP TABLE IF EXISTS $filingRules');
        }
        if (oldVersion < 14) {
          // Added for a lifecycle-review feature that was removed again
          // before release. The step stays and the version is not reused,
          // for the same reason v11 and v12 were left alone when filing
          // rules went: devices that already ran v14 have the column, and a
          // database opened at a *lower* version than it was written at is a
          // downgrade — which sqflite refuses, taking the whole app with it.
          //
          // Nothing reads the column. It costs one nullable integer per row.
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN kept_at INTEGER',
          );
        }
        if (oldVersion < 15) {
          // What the user said they were going to *do* with a screenshot, and
          // when they ticked it off. Two columns rather than one because they
          // answer different questions and change at different times — the
          // intent is set once at capture, done-ness flips later and can flip
          // back.
          //
          // Additive, so nothing existing moves: every row already here simply
          // has no intent, which is the correct answer for a screenshot saved
          // before the question was ever asked.
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN intent TEXT',
          );
          await db.execute(
            'ALTER TABLE $screenshotMeta ADD COLUMN intent_done_at INTEGER',
          );
        }
        if (oldVersion < 16) {
          // Intents the user names themselves. Purely additive: an existing
          // database has none, and every screenshot already in it keeps
          // pointing at a built-in id that this table has nothing to say
          // about.
          await _createCustomIntents(db);
        }
        if (oldVersion < 17) {
          await _adoptEverythingOntoThisDevice(db);
        }
      },
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_private INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $screenshotMeta (
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
        PRIMARY KEY (user_id, asset_id),
        FOREIGN KEY (folder_id) REFERENCES $folders (id) ON DELETE SET NULL
      )
    ''');
    await _createLibraryAssets(db);
    await _createCustomIntents(db);
    // Deliberately left empty on a fresh install: a brand-new database has no
    // pre-ownership images, so the adoption step must never run for it.
    await _createAppFlags(db);
  }

  Future<void> _createCustomIntents(Database db) async {
    // The id is a string generated by the app rather than an AUTOINCREMENT
    // integer, because it is written into `screenshot_meta.intent` alongside
    // built-in ids like 'buy' — one namespace, one column, and no way for a
    // row id to ever collide with a verb.
    // `IF NOT EXISTS` because the v2 step recreates the whole schema from
    // scratch, and a database old enough to run that also runs every later
    // step afterwards — including this one, which would otherwise fail on a
    // table it had just made.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $customIntents (
        user_id TEXT NOT NULL,
        id TEXT NOT NULL,
        label TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, id)
      )
    ''');
  }

  Future<void> _createLibraryAssets(Database db) async {
    // No foreign key to anything: the asset lives in the device gallery, not
    // in this database, and the row has to survive the image being missing
    // (moved to another device, restored from a backup) without cascading.
    await db.execute('''
      CREATE TABLE $libraryAssets (
        user_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, asset_id)
      )
    ''');
  }

  Future<void> _createAppFlags(Database db) async {
    await db.execute('''
      CREATE TABLE $appFlags (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Decides who owns the screenshots that were already in Shoto's album
  /// before ownership was recorded.
  ///
  /// Only deliberate organization counts as proof: favoriting a screenshot or
  /// filing it into a folder is something a person did on purpose, and
  /// `screenshot_meta` records which account did it. Every *other* row in
  /// that table is a cache — search stores OCR text there and the duplicate
  /// scan stores a hash — written by merely looking at the library, so it
  /// says nothing about whose screenshot it is.
  ///
  /// Everything left over has no honest owner in the data, so the first
  /// account to open the library adopts it, once, on this device. See
  /// [LibraryOwnershipLocalDataSource.hasPendingLegacyAdoption].
  Future<void> _seedLibraryOwnership(Database db) async {
    await db.execute(
      'INSERT OR IGNORE INTO $libraryAssets (user_id, asset_id, added_at) '
      'SELECT user_id, asset_id, updated_at FROM $screenshotMeta '
      'WHERE is_favorite = 1 OR folder_id IS NOT NULL',
    );
    await db.insert(appFlags, {
      'key': legacyLibraryAdoptedFlag,
      'value': '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Hands every row on this device to [LocalIdentity], whatever account it
  /// was filed under before.
  ///
  /// Signing in is no longer how you get into Shoto, so `user_id` can no
  /// longer mean "which Google account". If it kept meaning that, the first
  /// launch after this upgrade would show an empty library to somebody whose
  /// screenshots are all still there — filed under a uid nothing asks for any
  /// more — and signing out later would empty it again. The library belongs to
  /// the phone now, and this is the one-time step that makes the stored data
  /// agree with that.
  ///
  /// `UPDATE OR REPLACE` rather than a plain UPDATE because three of these
  /// four tables have `user_id` in their primary key: on a device where two
  /// accounts had both saved the same screenshot, re-pointing the second one
  /// collides with the first. Replace resolves that by keeping one row, which
  /// is the only sane answer — the two rows describe the same image on the
  /// same phone, and there is now only one person for them to belong to.
  ///
  /// Folders are the exception and simply merge: their primary key is an
  /// autoincrement id, so nothing collides. Two accounts that each had a
  /// "Receipts" folder end up with two folders of that name, which is
  /// recoverable by hand and better than silently dropping one of them.
  Future<void> _adoptEverythingOntoThisDevice(Database db) async {
    final String deviceId = _localIdentity.id;

    await db.transaction((txn) async {
      for (final String table in <String>[
        folders,
        screenshotMeta,
        libraryAssets,
        customIntents,
      ]) {
        await txn.rawUpdate(
          'UPDATE OR REPLACE $table SET user_id = ? WHERE user_id != ?',
          <Object?>[deviceId, deviceId],
        );
      }
    });
  }
}
