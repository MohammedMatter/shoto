import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Single shared sqflite connection for all locally-owned organization data
/// (folders, favorites, folder assignment). The screenshots themselves are
/// never duplicated here — only references to their gallery asset ids.
///
/// Every row is scoped to the signed-in Firebase user (`user_id`), so two
/// different accounts using the same device never see each other's data —
/// see [LibraryOwnershipLocalDataSource] (which screenshots are even *in*
/// your library), [ScreenshotMetadataLocalDataSource] and
/// [FoldersLocalDataSource] for where that scoping is applied.
class AppDatabase {
  static const String folders = 'folders';
  static const String screenshotMeta = 'screenshot_meta';

  /// Which account each image in SHOTO's album belongs to.
  ///
  /// The album on disk is one folder shared by the whole device — it has no
  /// idea accounts exist. Without this table every account signing in on the
  /// same phone saw every other account's screenshots, because "the library"
  /// was really just "the contents of Pictures/SHOTO". Membership is a
  /// decision the app makes, so it belongs here rather than on the filesystem.
  static const String libraryAssets = 'library_assets';

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

  /// Set to '1' once the images that were already in SHOTO's album before
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

  Future<Database> _open() async {
    final String path = join(await getDatabasesPath(), 'shoto.db');
    return openDatabase(
      path,
      version: 13,
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
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, asset_id),
        FOREIGN KEY (folder_id) REFERENCES $folders (id) ON DELETE SET NULL
      )
    ''');
    await _createLibraryAssets(db);
    // Deliberately left empty on a fresh install: a brand-new database has no
    // pre-ownership images, so the adoption step must never run for it.
    await _createAppFlags(db);
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

  /// Decides who owns the screenshots that were already in SHOTO's album
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
}
