import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/services/library_indexer.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';

/// The indexer exists to remove three capped, screen-bound indexers, so what
/// matters is that it does the reading **once** and can always finish: it
/// must not re-read what is cached, must not loop forever on a file it cannot
/// open, and must not run two sweeps over the same library at the same time.
void main() {
  ScreenshotEntity screenshot(String id) => ScreenshotEntity(
    asset: AssetEntity(
      id: id,
      typeInt: AssetType.image.index,
      width: 1080,
      height: 2400,
    ),
    isFavorite: false,
    folderId: null,
  );

  LibraryIndexer indexerFor(_FakeScreenshots repo, {bool premium = true}) {
    return LibraryIndexer(
      repo,
      GetSubscriptionStatusUseCase(_FakeSubscription(premium)),
    );
  }

  group('what it decides to read', () {
    test('reads only what is not cached', () async {
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('a'), screenshot('b'), screenshot('c')],
        // 'a' is fully read already; 'b' has text but was never labelled.
        ocr: {'a': 'hello', 'b': 'world'},
        labels: {'a': ['Cat']},
      );

      await indexerFor(repo).start();

      expect(repo.textReads, ['c']);
      expect(repo.labelReads, ['b', 'c']);
    });

    test('an empty cached result counts as read, not as missing', () async {
      // Both caches store an empty result rather than null precisely so that
      // "looked, found nothing" survives. Treating it as unread would re-run
      // the vision model over every wordless screenshot on every sweep.
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('a')],
        ocr: {'a': ''},
        labels: {'a': []},
      );

      await indexerFor(repo).start();

      expect(repo.textReads, isEmpty);
      expect(repo.labelReads, isEmpty);
      expect(indexerFor(repo).phase, IndexPhase.idle);
    });

    test('a fully-read library ends up-to-date having read nothing', () async {
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('a')],
        ocr: {'a': 'hi'},
        labels: {'a': ['Cat']},
      );

      final LibraryIndexer indexer = indexerFor(repo);
      await indexer.start();

      expect(indexer.phase, IndexPhase.upToDate);
      expect(indexer.remaining, 0);
      expect(repo.textReads, isEmpty);
    });
  });

  group('finishing, whatever the library contains', () {
    test('one unreadable screenshot does not stop the others', () async {
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('a'), screenshot('broken'), screenshot('c')],
        unopenable: {'broken'},
      );

      final LibraryIndexer indexer = indexerFor(repo);
      await indexer.start();

      expect(indexer.phase, IndexPhase.upToDate);
      expect(repo.textReads, containsAll(<String>['a', 'c']));
    });

    test('and is not attempted again on the next sweep', () async {
      // Recognition caches nothing when the file cannot be opened, so without
      // remembering it the same file returns to every worklist forever and
      // the indexer reports work it can never complete.
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('broken')],
        unopenable: {'broken'},
      );

      final LibraryIndexer indexer = indexerFor(repo);
      await indexer.start();
      expect(repo.textReads, ['broken']);

      await indexer.start();
      expect(
        repo.textReads,
        ['broken'],
        reason: 'the unreadable file was picked up a second time',
      );
      expect(indexer.phase, IndexPhase.upToDate);
    });
  });

  group('refusing to run', () {
    test('a free account is not indexed, and says so', () async {
      // Reading the library *is* search and rules; doing it for free would
      // give the paid feature away in advance.
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('a')],
      );

      final LibraryIndexer indexer = indexerFor(repo, premium: false);
      await indexer.start();

      expect(indexer.phase, IndexPhase.notPremium);
      expect(repo.textReads, isEmpty);
    });

    test('two sweeps never run over the same library at once', () async {
      // start() is called from the shell, from search and from both rules
      // screens, deliberately without any of them coordinating.
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [screenshot('a'), screenshot('b')],
      );

      final LibraryIndexer indexer = indexerFor(repo);
      await Future.wait([indexer.start(), indexer.start(), indexer.start()]);

      expect(repo.textReads, ['a', 'b']);
    });

    test('a disposed indexer stops rather than notifying', () async {
      final _FakeScreenshots repo = _FakeScreenshots(
        library: [for (int i = 0; i < 30; i++) screenshot('$i')],
      );

      final LibraryIndexer indexer = indexerFor(repo);
      final Future<void> sweep = indexer.start();
      indexer.dispose();
      await sweep;

      // A ChangeNotifier throws if notified after dispose, so finishing this
      // test at all is the assertion. The sweep also has to stop early rather
      // than walk all thirty.
      expect(repo.textReads.length, lessThan(30));
    });
  });
}

/// Only the members the indexer touches; everything else is a deliberate
/// error rather than a silent default, so this fake cannot drift into
/// answering questions the test did not think about.
class _FakeScreenshots implements ScreenshotRepository {
  final List<ScreenshotEntity> library;
  final Map<String, String> ocr;
  final Map<String, List<String>> labels;

  /// Ids whose file cannot be opened — recognition returns empty and caches
  /// nothing, exactly as the real implementation does when `asset.file` is
  /// null.
  final Set<String> unopenable;

  final List<String> textReads = [];
  final List<String> labelReads = [];

  _FakeScreenshots({
    required this.library,
    Map<String, String>? ocr,
    Map<String, List<String>>? labels,
    this.unopenable = const {},
  }) : ocr = {...?ocr},
       labels = {...?labels};

  @override
  Future<List<ScreenshotEntity>> getAllScreenshots() async => library;

  @override
  Future<Map<String, String>> getCachedOcrText() async => {...ocr};

  @override
  Future<Map<String, List<String>>> getCachedVisualLabels() async => {
    for (final MapEntry<String, List<String>> e in labels.entries)
      e.key: List.of(e.value),
  };

  @override
  Future<String> extractAndCacheText(ScreenshotEntity screenshot) async {
    textReads.add(screenshot.id);
    if (unopenable.contains(screenshot.id)) return '';
    ocr[screenshot.id] = 'text for ${screenshot.id}';
    return ocr[screenshot.id]!;
  }

  @override
  Future<List<String>> extractAndCacheLabels(
    ScreenshotEntity screenshot,
  ) async {
    labelReads.add(screenshot.id);
    if (unopenable.contains(screenshot.id)) return const [];
    labels[screenshot.id] = const ['Cat'];
    return const ['Cat'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'the indexer reached ${invocation.memberName}, which it should not',
  );
}

class _FakeSubscription implements SubscriptionRepository {
  final bool premium;
  _FakeSubscription(this.premium);

  @override
  Future<SubscriptionStatus> getStatus() async =>
      premium ? SubscriptionStatus.tester : SubscriptionStatus.free;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
