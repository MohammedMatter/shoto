import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/data/data_sources/library_ownership_local_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The read Home's first frame is built on.
///
/// **Worth a test because it is a second implementation of a question the app
/// already answers elsewhere.** `ScreenshotEntity.isUnsorted` and
/// `IntentState.isWaiting` decide these same two things once the gallery has
/// been read; the summary decides them straight off the columns, because it
/// runs before there is any entity to ask. Two answers to one question drift,
/// and the way this one would drift is the worst possible: Home would open on
/// a confident number and then correct itself a second later, which is exactly
/// the flicker the summary exists to remove.
///
/// So the cases below are the ones where a careless query gives a different
/// answer from the entity:
///
/// * a screenshot with **no `screenshot_meta` row at all**, which is what most
///   of the unsorted pile is and what an inner join would silently drop;
/// * an intent that has been **ticked off**, which is still an intent and is no
///   longer waiting;
/// * a row belonging to **another device identity**, which is not in this
///   library at all.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const String deviceId = 'local:test-device';
  const String otherDevice = 'local:someone-else';

  late LibraryOwnershipLocalDataSource ownership;
  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final LocalIdentity identity = LocalIdentity();
    await identity.overrideForTesting(deviceId);

    final AppDatabase appDatabase = AppDatabase(identity);
    // The data source opens the connection itself, through the same getter —
    // seeding a file opened separately would test one database and read
    // another, which is a mistake this test made once already.
    db = await appDatabase.database;
    ownership = LibraryOwnershipLocalDataSource(appDatabase, identity);
  });

  tearDown(() async {
    await db.close();
    await databaseFactory.deleteDatabase(db.path);
  });

  /// Puts [assetId] in [owner]'s library, optionally with organization on it.
  Future<void> seed(
    String assetId, {
    String owner = deviceId,
    bool hasMeta = true,
    int? folderId,
    bool isFavorite = false,
    String? intent,
    int? intentDoneAt,
  }) async {
    await db.insert(AppDatabase.libraryAssets, <String, Object?>{
      'user_id': owner,
      'asset_id': assetId,
      'added_at': 0,
    });
    if (!hasMeta) return;
    await db.insert(AppDatabase.screenshotMeta, <String, Object?>{
      'user_id': owner,
      'asset_id': assetId,
      'folder_id': folderId,
      'is_favorite': isFavorite ? 1 : 0,
      'intent': intent,
      'intent_done_at': intentDoneAt,
      'updated_at': 0,
    });
  }

  /// The same two conditions the repository applies, so this file tests the
  /// query rather than restating the aggregation.
  int unsortedIn(List<Map<String, Object?>> rows) => rows.where((row) {
    return row['folder_id'] == null && (row['is_favorite'] as int?) != 1;
  }).length;

  test('a screenshot with no metadata row at all still counts', () async {
    // The whole unsorted pile is made of these: imported, never touched, so
    // nothing ever wrote a `screenshot_meta` row for it.
    await seed('never-touched', hasMeta: false);

    final List<Map<String, Object?>> rows = await ownership
        .getOrganizationFacts();

    expect(rows, hasLength(1));
    expect(unsortedIn(rows), 1);
  });

  test('filed and favourited screenshots are not unsorted', () async {
    // A real folder row, because `screenshot_meta.folder_id` is a foreign key.
    final int folderId = await db.insert(AppDatabase.folders, <String, Object?>{
      'user_id': deviceId,
      'name': 'Receipts',
      'color': 0xFF5B8DEF,
      'created_at': 0,
    });

    await seed('loose', hasMeta: false);
    await seed('filed', folderId: folderId);
    await seed('starred', isFavorite: true);

    final List<Map<String, Object?>> rows = await ownership
        .getOrganizationFacts();

    expect(rows, hasLength(3));
    expect(unsortedIn(rows), 1);
  });

  test('a ticked-off intent is no longer waiting', () async {
    await seed('still-waiting', intent: ScreenshotIntent.pay.id);
    await seed('done', intent: ScreenshotIntent.pay.id, intentDoneAt: 1700);

    final List<Map<String, Object?>> rows = await ownership
        .getOrganizationFacts();
    final Iterable<Map<String, Object?>> waiting = rows.where(
      (Map<String, Object?> row) =>
          row['intent'] != null && row['intent_done_at'] == null,
    );

    expect(waiting, hasLength(1));
  });

  test('another identity\'s library is not in this one', () async {
    await seed('mine', hasMeta: false);
    await seed('theirs', owner: otherDevice, hasMeta: false);

    final List<Map<String, Object?>> rows = await ownership
        .getOrganizationFacts();

    expect(rows, hasLength(1));
  });

  test('the summary is empty for a library nobody has put anything in', () async {
    expect(await ownership.getOrganizationFacts(), isEmpty);
  });
}
