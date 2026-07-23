import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Single shared sqflite connection for all locally-owned organization data
/// (folders, favorites, folder assignment). The screenshots themselves are
/// never duplicated here — only references to their gallery asset ids.
class AppDatabase {
  static const String folders = 'folders';
  static const String screenshotMeta = 'screenshot_meta';

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final String path = join(await getDatabasesPath(), 'shoto.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $screenshotMeta (
            asset_id TEXT PRIMARY KEY,
            folder_id INTEGER,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (folder_id) REFERENCES $folders (id) ON DELETE SET NULL
          )
        ''');
      },
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }
}
