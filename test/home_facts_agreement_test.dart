import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/data/data_sources/custom_intents_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/image_labeling_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/library_ownership_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';
import 'package:shoto/features/screenshots/data/repositories_impl/screenshot_repository_impl.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

import 'support/fake_gallery.dart';

/// **The one rule in this app that is written down twice.**
///
/// Home draws its inbox — and, more importantly, *chooses its layout* — from
/// two different sources depending on how far the read has got:
///
/// * before the gallery answers, from `LibrarySummary`, counted in
///   `ScreenshotRepositoryImpl.getLibrarySummary` straight off database
///   columns;
/// * after it answers, from `ScreenshotsLoadedState`, counted through
///   `ScreenshotEntity.isUnsorted` and `IntentState.isWaiting`.
///
/// They must produce identical numbers for identical data. `getLibrarySummary`
/// cannot call the getters — an entity needs an `AssetEntity`, which is the
/// gallery read the summary exists to skip — so the two implementations are
/// kept in step **by a comment**, and the comment says so:
///
/// > if either definition ever changes, it changes here too.
///
/// If they drift, nothing throws. Home lays itself out from one answer and
/// then rearranges to the other a second later: Recent and Tools swap places,
/// the search bar appears or vanishes, the count on the card changes. Every
/// widget test in `home_loaded_layout_test.dart` still passes, because each
/// half is internally consistent — the defect only exists *between* them.
///
/// So this feeds one library through both paths and compares.
class _FakeOwnership implements LibraryOwnershipLocalDataSource {
  _FakeOwnership(this.rows);
  final List<Map<String, Object?>> rows;

  @override
  Future<List<Map<String, Object?>>> getOrganizationFacts() async => rows;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomIntents implements CustomIntentsLocalDataSource {
  _FakeCustomIntents(this.intents);
  final List<CustomIntent> intents;

  @override
  Future<List<CustomIntent>> getCustomIntents() async => intents;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGalleryDataSource implements ScreenshotGalleryDataSource {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMetadata implements ScreenshotMetadataLocalDataSource {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeText implements TextRecognitionDataSource {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLabels implements ImageLabelingDataSource {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One screenshot, described once, rendered into both shapes.
///
/// Writing the case once is the whole point: a fixture that built the row and
/// the entity from separate literals could disagree with itself and the test
/// would happily prove the two implementations agree about different data.
class _Case {
  final int? folderId;
  final bool isFavorite;
  final IntentRef? intent;
  final bool done;

  const _Case({
    this.folderId,
    this.isFavorite = false,
    this.intent,
    this.done = false,
  });

  Map<String, Object?> get row => <String, Object?>{
    'folder_id': folderId,
    'is_favorite': isFavorite ? 1 : 0,
    'intent': intent?.id,
    'intent_done_at': done ? 1 : null,
  };

  ScreenshotEntity entity(int index) => ScreenshotEntity(
    asset: FakeGallery.asset(index % 12),
    isFavorite: isFavorite,
    folderId: folderId,
    intent: intent == null
        ? null
        : IntentState(ref: intent!, doneAt: done ? DateTime(2026) : null),
  );
}

void main() {
  // A plain `test` never builds a widget, so nothing has initialized the
  // binding — and `FakeGallery` installs a channel mock, which needs one.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => FakeGallery.install());

  const CustomIntent mine = CustomIntent(
    id: '${IntentRef.customPrefix}7',
    label: 'Frame it',
    iconKey: 'star',
    sortOrder: 0,
  );

  Future<LibrarySummary> summaryOf(
    List<_Case> cases, {
    List<CustomIntent> custom = const <CustomIntent>[],
  }) {
    final ScreenshotRepositoryImpl repository = ScreenshotRepositoryImpl(
      _FakeGalleryDataSource(),
      _FakeMetadata(),
      _FakeCustomIntents(custom),
      _FakeOwnership(cases.map((_Case c) => c.row).toList()),
      _FakeText(),
      _FakeLabels(),
    );
    return repository.getLibrarySummary();
  }

  ScreenshotsLoadedState loadedOf(List<_Case> cases) => ScreenshotsLoadedState(
    screenshots: <ScreenshotEntity>[
      for (int i = 0; i < cases.length; i++) cases[i].entity(i),
    ],
  );

  /// Asserts the two paths agree about one library, on every number Home reads.
  Future<void> expectAgreement(
    List<_Case> cases, {
    List<CustomIntent> custom = const <CustomIntent>[],
  }) async {
    final LibrarySummary summary = await summaryOf(cases, custom: custom);
    final ScreenshotsLoadedState loaded = loadedOf(cases);

    expect(summary.total, loaded.screenshots.length, reason: 'total');
    expect(
      summary.unsorted,
      loaded.screenshots.where((ScreenshotEntity s) => s.isUnsorted).length,
      reason: 'unsorted',
    );
    expect(summary.waiting, loaded.waitingByIntent, reason: 'waiting');

    // The order matters as much as the contents: these become a row of chips,
    // and a different order on either side of the read is the tags visibly
    // rearranging themselves.
    expect(
      summary.waiting.keys.toList(),
      loaded.waitingByIntent.keys.toList(),
      reason: 'waiting order',
    );

    // And the condition Home actually branches its *layout* on.
    final bool clearBySummary =
        !summary.isEmpty && summary.unsorted == 0 && summary.waiting.isEmpty;
    final bool clearByLoaded =
        loaded.waitingByIntent.isEmpty &&
        !loaded.screenshots.any((ScreenshotEntity s) => s.isUnsorted);
    expect(
      clearBySummary,
      clearByLoaded,
      reason: 'the two answers to "is anything waiting" must match, or Recent '
          'and Tools swap places when the read lands',
    );
  }

  group('the summary and the loaded list count the same library', () {
    test('nothing filed and nothing starred is all unsorted', () async {
      await expectAgreement(const <_Case>[_Case(), _Case(), _Case()]);
    });

    test('a folder takes a screenshot out of the unsorted pile', () async {
      await expectAgreement(const <_Case>[
        _Case(folderId: 1),
        _Case(folderId: 2),
        _Case(),
      ]);
    });

    test('a star does too, on its own', () async {
      // The half of `isUnsorted` most easily forgotten when the rule is
      // rewritten against columns: filed *or* starred, not filed alone.
      await expectAgreement(const <_Case>[
        _Case(isFavorite: true),
        _Case(isFavorite: true, folderId: 3),
        _Case(),
      ]);
    });

    test('an intent that is done is not waiting', () async {
      await expectAgreement(const <_Case>[
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.read)),
        _Case(
          folderId: 1,
          intent: BuiltInIntent(ScreenshotIntent.read),
          done: true,
        ),
      ]);
    });

    test('several verbs are grouped and counted separately', () async {
      await expectAgreement(const <_Case>[
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.buy)),
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.buy)),
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.pay)),
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.read)),
      ]);
    });

    test('the verbs come back in the same order from both sides', () async {
      // Deliberately inserted out of order: both sides sort by
      // `IntentRef.pickerOrder`, and this is the case that proves neither is
      // simply returning insertion order and getting away with it.
      await expectAgreement(const <_Case>[
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.fix)),
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.buy)),
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.watch)),
        _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.read)),
      ]);
    });

    test('a user-written verb is resolved, not dropped', () async {
      // The summary has to look custom intents up in a second table; the
      // loaded list already carries the object. A miss here shows as a chip
      // that exists after the read and not before it.
      await expectAgreement(
        const <_Case>[
          _Case(folderId: 1, intent: mine),
          _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.buy)),
        ],
        custom: const <CustomIntent>[mine],
      );
    });

    test("a user's own verb sorts after every built-in, on both sides", () async {
      await expectAgreement(
        const <_Case>[
          _Case(folderId: 1, intent: mine),
          _Case(folderId: 1, intent: BuiltInIntent(ScreenshotIntent.fix)),
        ],
        custom: const <CustomIntent>[mine],
      );
    });

    test('an empty library agrees that it is empty', () async {
      final LibrarySummary summary = await summaryOf(const <_Case>[]);
      expect(summary.isEmpty, isTrue);
      expect(loadedOf(const <_Case>[]).screenshots, isEmpty);
    });

    test('every combination of filed, starred, waiting and done agrees', () async {
      // The exhaustive pass. Sixteen shapes is small enough to enumerate and
      // is where a rewritten predicate actually goes wrong — not on the plain
      // cases above, but on a corner like *starred and filed and done*.
      final List<_Case> all = <_Case>[
        for (final int? folder in <int?>[null, 1])
          for (final bool star in <bool>[false, true])
            for (final IntentRef? ref in <IntentRef?>[
              null,
              const BuiltInIntent(ScreenshotIntent.read),
            ])
              for (final bool done in <bool>[false, true])
                _Case(
                  folderId: folder,
                  isFavorite: star,
                  intent: ref,
                  done: done,
                ),
      ];
      await expectAgreement(all);
    });
  });
}
