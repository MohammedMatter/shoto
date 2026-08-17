import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/features/folders/data/data_sources/folders_local_data_source.dart';
import 'package:shoto/features/folders/data/models/folder_model.dart';
import 'package:shoto/features/folders/data/repositories_impl/folders_repository_impl.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/delete_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/seed_default_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/update_folder_use_case.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The folder table, against real SQLite rather than a stand-in.
///
/// Everything in this file is a promise the *user* can see the breaking of, and
/// none of them is visible in a widget test:
///
/// * deleting a folder must not delete what was filed in it — the sheet that
///   asks for the deletion says so in as many words ("Screenshots inside are
///   kept"), and that promise is kept by one `ON DELETE SET NULL` in the
///   schema, three files away from the code that makes it;
/// * the starter folders must be offered exactly once in the life of an
///   install, however the user answered — re-seeding a set somebody deleted is
///   the loudest way an app can say it was not listening;
/// * every read and every write is scoped to a `user_id`, and a missed scope on
///   an `UPDATE` or a `DELETE` reaches rows the caller was never shown.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const String deviceId = 'local:folders-test-device';
  const String otherId = 'local:some-other-identity';

  late Directory dir;
  late _TempAppDatabase appDatabase;
  late LocalIdentity identity;
  late FoldersLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    identity = LocalIdentity();
    await identity.overrideForTesting(deviceId);

    dir = await Directory.systemTemp.createTemp('shoto_folders_test');
    appDatabase = _TempAppDatabase(identity, '${dir.path}/shoto.db');
    dataSource = FoldersLocalDataSource(appDatabase, identity);
  });

  tearDown(() async {
    await appDatabase.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// Files a screenshot into [folderId] the way the metadata source does, so
  /// the counts and the delete behaviour are being tested against rows shaped
  /// like the real ones.
  Future<void> fileScreenshot(
    String assetId, {
    int? folderId,
    String userId = deviceId,
  }) async {
    final Database db = await appDatabase.database;
    await db.insert(AppDatabase.screenshotMeta, <String, Object?>{
      'user_id': userId,
      'asset_id': assetId,
      'folder_id': folderId,
      'is_favorite': 0,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  group('creating', () {
    test('a folder comes back with every field it was given', () async {
      final FolderModel created = await dataSource.createFolder(
        'Receipts',
        0xFF5B8DEF,
        isPrivate: true,
        iconKey: 'receipt',
      );

      expect(created.id, greaterThan(0));
      expect(created.name, 'Receipts');
      expect(created.color, 0xFF5B8DEF);
      expect(created.isPrivate, isTrue);
      expect(created.iconKey, 'receipt');

      // And the row that was actually written agrees with the object handed
      // back — the two are built separately, so they can disagree.
      final FolderEntity stored = (await dataSource.getFolders()).single;
      expect(stored.id, created.id);
      expect(stored.name, created.name);
      expect(stored.color, created.color);
      expect(stored.isPrivate, created.isPrivate);
      expect(stored.iconKey, created.iconKey);
      expect(stored.createdAt, created.createdAt);
    });

    test('the defaults are unlocked and without a glyph', () async {
      await dataSource.createFolder('Plain', 0xFF33E0C2);

      final FolderEntity stored = (await dataSource.getFolders()).single;
      expect(stored.isPrivate, isFalse);
      // Null rather than 'folder': the presentation layer owns the fallback,
      // and a folder that was never given a glyph must stay distinguishable
      // from one somebody deliberately set to the plain folder.
      expect(stored.iconKey, isNull);
      expect(stored.screenshotCount, 0);
    });

    test('a restore can re-create a folder at the time it was made', () async {
      // The one caller that passes `createdAt`. Without it every restored
      // folder is stamped with the moment of the restore, which puts a
      // two-year-old folder at the top of a grid sorted by newest first.
      final DateTime made = DateTime(2024, 3, 9, 14, 20, 31);
      await dataSource.createFolder(
        'From a backup',
        0xFFFFC857,
        createdAt: made,
      );

      expect((await dataSource.getFolders()).single.createdAt, made);
    });

    test('names survive the round trip intact', () async {
      // Quotes are what a hand-written SQL string would break on, and the
      // rest is what a real person types into a filing label.
      const List<String> names = <String>[
        "Mum's recipes",
        'Trips — 2026 ✈️',
        'Ünicode & "quoted"',
        '  ',
      ];
      for (final String name in names) {
        await dataSource.createFolder(name, 0xFF8B7BF0);
      }

      final Set<String> stored = (await dataSource.getFolders())
          .map((FolderEntity f) => f.name)
          .toSet();
      expect(stored, names.toSet());
    });
  });

  group('reading', () {
    test('folders come back newest first', () async {
      final DateTime base = DateTime(2026, 1, 1);
      await dataSource.createFolder('oldest', 1, createdAt: base);
      await dataSource.createFolder(
        'newest',
        2,
        createdAt: base.add(const Duration(days: 2)),
      );
      await dataSource.createFolder(
        'middle',
        3,
        createdAt: base.add(const Duration(days: 1)),
      );

      expect(
        (await dataSource.getFolders()).map((FolderEntity f) => f.name),
        <String>['newest', 'middle', 'oldest'],
      );
    });

    test('the count is what is actually filed in each folder', () async {
      final FolderModel full = await dataSource.createFolder('Full', 1);
      await dataSource.createFolder('Empty', 2);

      await fileScreenshot('a', folderId: full.id);
      await fileScreenshot('b', folderId: full.id);
      // Filed nowhere: in the library, but in no folder. It must not be
      // counted against anything.
      await fileScreenshot('c');

      final Map<String, int> counts = <String, int>{
        for (final FolderEntity f in await dataSource.getFolders())
          f.name: f.screenshotCount,
      };
      expect(counts, <String, int>{'Full': 2, 'Empty': 0});
    });

    test("another identity's screenshots are not counted", () async {
      final FolderModel mine = await dataSource.createFolder('Mine', 1);

      await fileScreenshot('mine', folderId: mine.id);
      // The same folder id, owned by somebody else. The count query is
      // scoped by `user_id` as well as by folder, and dropping that scope
      // would inflate the number on the card.
      await fileScreenshot('theirs', folderId: mine.id, userId: otherId);

      expect((await dataSource.getFolders()).single.screenshotCount, 1);
    });
  });

  group('editing', () {
    test('name, colour and glyph all change in one write', () async {
      final FolderModel folder = await dataSource.createFolder(
        'Before',
        0xFF5B8DEF,
        iconKey: 'folder',
      );

      await dataSource.updateFolder(
        folder.id,
        name: 'After',
        color: 0xFFEF5DA8,
        iconKey: 'music',
      );

      final FolderEntity updated = (await dataSource.getFolders()).single;
      expect(updated.name, 'After');
      expect(updated.color, 0xFFEF5DA8);
      expect(updated.iconKey, 'music');
    });

    test('a null glyph clears the one that was there', () async {
      // The column is nullable and null is a real answer, so an update that
      // carries none has to write it — leaving the old key would make the
      // glyph the one field on this sheet that cannot be taken back.
      final FolderModel folder = await dataSource.createFolder(
        'Had a glyph',
        1,
        iconKey: 'music',
      );

      await dataSource.updateFolder(folder.id, name: 'Had a glyph', color: 1);

      expect((await dataSource.getFolders()).single.iconKey, isNull);
    });

    test('the lock survives an edit', () async {
      // `updateFolder` deliberately does not carry `is_private` — the editor
      // sheet offers the switch on creation only. What it must not do is
      // quietly reset the column it never mentions.
      final FolderModel folder = await dataSource.createFolder(
        'Bank',
        1,
        isPrivate: true,
      );

      await dataSource.updateFolder(
        folder.id,
        name: 'Bank statements',
        color: 2,
      );

      expect((await dataSource.getFolders()).single.isPrivate, isTrue);
    });

    test('editing a folder that no longer exists is a no-op', () async {
      // Two phones' worth of races end here: the actions sheet holds a folder
      // captured when the grid loaded, and it can be saved after a delete.
      await dataSource.updateFolder(4242, name: 'Ghost', color: 1);

      expect(await dataSource.getFolders(), isEmpty);
    });
  });

  group('deleting', () {
    test('the screenshots inside are kept, unfiled', () async {
      // This is the sentence printed under the delete button, and it is kept
      // by `ON DELETE SET NULL` plus `PRAGMA foreign_keys = ON`. Either one
      // missing and deleting a folder deletes a year of someone's filing —
      // or worse, leaves the rows pointing at a folder that is gone.
      final FolderModel folder = await dataSource.createFolder('Doomed', 1);
      await fileScreenshot('kept', folderId: folder.id);

      await dataSource.deleteFolder(folder.id);

      final Database db = await appDatabase.database;
      final List<Map<String, Object?>> rows = await db.query(
        AppDatabase.screenshotMeta,
      );
      expect(rows, hasLength(1), reason: 'the screenshot row was deleted');
      expect(rows.single['asset_id'], 'kept');
      expect(
        rows.single['folder_id'],
        isNull,
        reason: 'the row still points at a folder that no longer exists',
      );
    });

    test('only the folder asked for goes', () async {
      final FolderModel keep = await dataSource.createFolder('Keep', 1);
      final FolderModel drop = await dataSource.createFolder('Drop', 2);

      await dataSource.deleteFolder(drop.id);

      final List<FolderEntity> left = await dataSource.getFolders();
      expect(left.map((FolderEntity f) => f.id), <int>[keep.id]);
    });
  });

  /// The `user_id` scope, from the outside.
  ///
  /// Every statement in the data source carries `WHERE user_id = ?`, and a
  /// missing one is invisible on a phone with a single identity — which is
  /// every phone, until a restored backup or a second install makes it two.
  group('scoping', () {
    /// Writes a folder owned by somebody else, straight to the table, and
    /// returns its id.
    Future<int> otherUsersFolder() async {
      final Database db = await appDatabase.database;
      return db.insert(AppDatabase.folders, <String, Object?>{
        'user_id': otherId,
        'name': 'Not yours',
        'color': 0xFF000001,
        'is_private': 0,
        'icon_key': 'work',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    test("another identity's folders are never listed", () async {
      await otherUsersFolder();
      await dataSource.createFolder('Mine', 1);

      final List<FolderEntity> visible = await dataSource.getFolders();
      expect(visible.map((FolderEntity f) => f.name), <String>['Mine']);
    });

    test("another identity's folder cannot be edited", () async {
      final int theirs = await otherUsersFolder();

      await dataSource.updateFolder(theirs, name: 'Renamed', color: 9);

      final Database db = await appDatabase.database;
      final Map<String, Object?> row = (await db.query(
        AppDatabase.folders,
        where: 'id = ?',
        whereArgs: <Object?>[theirs],
      )).single;
      expect(row['name'], 'Not yours');
      expect(row['color'], 0xFF000001);
    });

    test("another identity's folder cannot be deleted", () async {
      final int theirs = await otherUsersFolder();

      await dataSource.deleteFolder(theirs);

      final Database db = await appDatabase.database;
      expect(
        await db.query(
          AppDatabase.folders,
          where: 'id = ?',
          whereArgs: <Object?>[theirs],
        ),
        hasLength(1),
      );
    });
  });

  group('seeding the starter folders', () {
    final List<FolderSeed> seeds = <FolderSeed>[
      const FolderSeed(name: 'Trips', color: 0xFF5B8DEF, iconKey: 'map'),
      const FolderSeed(name: 'Recipes', color: 0xFFF5883C, iconKey: 'food'),
      const FolderSeed(name: 'Money', color: 0xFFFFC857, iconKey: 'money'),
    ];

    test('the first call writes them and says so', () async {
      expect(await dataSource.seedDefaultFolders(seeds), isTrue);

      final List<FolderEntity> folders = await dataSource.getFolders();
      expect(folders, hasLength(3));
      expect(folders.every((FolderEntity f) => f.isPrivate == false), isTrue);
    });

    test('they arrive in the order they are listed', () async {
      // `getFolders` orders by `created_at DESC`, so the seeds are written a
      // millisecond apart on purpose. A single shared timestamp leaves the
      // order to SQLite, and the starter grid comes out backwards or shuffled.
      await dataSource.seedDefaultFolders(seeds);

      expect(
        (await dataSource.getFolders()).map((FolderEntity f) => f.name),
        <String>['Trips', 'Recipes', 'Money'],
      );
    });

    test('each seed keeps its own colour and glyph', () async {
      await dataSource.seedDefaultFolders(seeds);

      final Map<String, (int, String?)> got = <String, (int, String?)>{
        for (final FolderEntity f in await dataSource.getFolders())
          f.name: (f.color, f.iconKey),
      };
      expect(got['Trips'], (0xFF5B8DEF, 'map'));
      expect(got['Recipes'], (0xFFF5883C, 'food'));
      expect(got['Money'], (0xFFFFC857, 'money'));
    });

    test('a second call writes nothing and says so', () async {
      await dataSource.seedDefaultFolders(seeds);

      expect(await dataSource.seedDefaultFolders(seeds), isFalse);
      expect(await dataSource.getFolders(), hasLength(3));
    });

    test('deleting every starter folder does not bring them back', () async {
      // The whole reason the guard is a flag rather than "is the table
      // empty". Somebody who deletes all seven has answered the offer.
      await dataSource.seedDefaultFolders(seeds);
      for (final FolderEntity f in await dataSource.getFolders()) {
        await dataSource.deleteFolder(f.id);
      }

      expect(await dataSource.seedDefaultFolders(seeds), isFalse);
      expect(await dataSource.getFolders(), isEmpty);
    });

    test('a folder made by hand does not stop the offer', () async {
      // The mirror of the case above: the flag is about the offer, not about
      // the table, so somebody who made their own folder first is still
      // offered the set.
      await dataSource.createFolder('Mine, first', 1);

      expect(await dataSource.seedDefaultFolders(seeds), isTrue);
      expect(await dataSource.getFolders(), hasLength(4));
    });

    test('an empty set still counts as having been offered', () async {
      expect(await dataSource.seedDefaultFolders(const <FolderSeed>[]), isTrue);
      // The flag is written inside the same transaction as the (zero) inserts,
      // so a caller that seeds nothing must not be re-offered a full set on
      // the next launch.
      expect(await dataSource.seedDefaultFolders(seeds), isFalse);
      expect(await dataSource.getFolders(), isEmpty);
    });

    test('the flag is device-wide, not per identity', () async {
      // Documented behaviour rather than an accident: `app_flags` is keyed by
      // a bare string, and since v17 there is one identity per phone. A second
      // identity appearing (a restored backup) therefore gets no starter set,
      // which is the right answer — it is arriving with folders of its own.
      await dataSource.seedDefaultFolders(seeds);

      await identity.overrideForTesting(otherId);
      expect(await dataSource.seedDefaultFolders(seeds), isFalse);
      expect(await dataSource.getFolders(), isEmpty);
    });
  });

  /// The chain the app actually calls: use case → repository → data source.
  ///
  /// Thin by design, and that is exactly why it is worth one pass — a use case
  /// that drops a named argument on its way down compiles, passes every test
  /// written against the layer below it, and loses the user's choice.
  group('through the use cases', () {
    late GetFoldersUseCase getFolders;
    late CreateFolderUseCase createFolder;
    late UpdateFolderUseCase updateFolder;
    late DeleteFolderUseCase deleteFolder;
    late SeedDefaultFoldersUseCase seedDefaults;

    setUp(() {
      final FoldersRepositoryImpl repository = FoldersRepositoryImpl(
        dataSource,
      );
      getFolders = GetFoldersUseCase(repository);
      createFolder = CreateFolderUseCase(repository);
      updateFolder = UpdateFolderUseCase(repository);
      deleteFolder = DeleteFolderUseCase(repository);
      seedDefaults = SeedDefaultFoldersUseCase(repository);
    });

    test('every argument survives the trip down', () async {
      final FolderEntity created = await createFolder(
        'Locked and drawn',
        0xFFEF5DA8,
        isPrivate: true,
        iconKey: 'music',
      );

      FolderEntity read = (await getFolders()).single;
      expect(read.name, 'Locked and drawn');
      expect(read.color, 0xFFEF5DA8);
      expect(read.isPrivate, isTrue);
      expect(read.iconKey, 'music');

      await updateFolder(
        created.id,
        name: 'Renamed',
        color: 0xFF33E0C2,
        iconKey: 'fitness',
      );
      read = (await getFolders()).single;
      expect(read.name, 'Renamed');
      expect(read.color, 0xFF33E0C2);
      expect(read.iconKey, 'fitness');

      await deleteFolder(created.id);
      expect(await getFolders(), isEmpty);

      expect(
        await seedDefaults(<FolderSeed>[
          const FolderSeed(name: 'Seeded', color: 1, iconKey: 'map'),
        ]),
        isTrue,
      );
      expect((await getFolders()).single.name, 'Seeded');
    });
  });
}

/// The real [AppDatabase] — real schema, real migrations, real pragmas — kept
/// in a temp file rather than wherever the platform would put it.
///
/// A subclass rather than a stand-in, because half of what is being tested
/// here belongs to the schema itself: `ON DELETE SET NULL` and
/// `PRAGMA foreign_keys = ON` are the two lines that keep the promise the
/// delete sheet prints, and a hand-written table in a test file would test a
/// copy of them.
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
