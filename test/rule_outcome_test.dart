import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/presentation/widgets/library_insight.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// What a rule *matches* and what a rule *files* are different sets, and
/// reporting the first as if it were the second is the bug this pins.
///
/// A real rule read "claims 1 screenshot" and filed nothing, forever. The
/// count was true — one screenshot did match — but that screenshot was already
/// inside another folder, and a library run never moves those, on purpose:
/// re-filing something a person placed by hand is the failure that killed
/// automatic albums. The number promised something the app had already
/// decided never to do.
void main() {
  ScreenshotEntity shot(String id, {int? folderId}) => ScreenshotEntity(
    asset: AssetEntity(
      id: id,
      typeInt: AssetType.image.index,
      width: 1080,
      height: 2400,
    ),
    isFavorite: false,
    folderId: folderId,
  );

  FilingRule rule(String word, {int id = 1, int folderId = 7}) => FilingRule(
    id: id,
    name: 'Rule $id',
    folderId: folderId,
    conditions: [RuleCondition(type: ConditionType.textContains, value: word)],
  );

  test(
    'a match already in a folder is reported, not counted as filed',
    () async {
      final LibraryInsight insight = await LibraryInsight.load(
        _FakeScreenshots(
          library: [shot('a', folderId: 3)],
          ocr: {'a': 'IBAN GB33 BUKB 2020 1555 5555 55'},
        ),
      );

      final RuleOutcome outcome = insight.outcomeOf(
        rule('iban').conditions,
        RuleMatch.all,
        higherPriority: const [],
      );

      expect(outcome.matched, ['a'], reason: 'the rule really does match it');
      expect(outcome.alreadyFiled, ['a']);
      expect(
        outcome.filed,
        isEmpty,
        reason: 'a run will never move a screenshot that is already filed',
      );
      expect(outcome.isFullyInert, isTrue);
    },
  );

  test('an unfiled match is what the rule would actually take', () async {
    final LibraryInsight insight = await LibraryInsight.load(
      _FakeScreenshots(
        library: [shot('a'), shot('b', folderId: 3)],
        ocr: {'a': 'iban here', 'b': 'iban there'},
      ),
    );

    final RuleOutcome outcome = insight.outcomeOf(
      rule('iban').conditions,
      RuleMatch.all,
      higherPriority: const [],
    );

    expect(outcome.matched.length, 2);
    expect(outcome.filed, ['a']);
    expect(outcome.alreadyFiled, ['b']);
    expect(outcome.isFullyInert, isFalse);
  });

  test('a higher-priority rule takes precedence over both', () async {
    // Ordering matters for the message: "another rule got there first" and
    // "it is already filed" are different fixes — move this rule up, versus
    // this rule only applies to new screenshots.
    final LibraryInsight insight = await LibraryInsight.load(
      _FakeScreenshots(library: [shot('a')], ocr: {'a': 'iban invoice'}),
    );

    final RuleOutcome outcome = insight.outcomeOf(
      rule('iban').conditions,
      RuleMatch.all,
      higherPriority: [rule('invoice', id: 2, folderId: 9)],
    );

    expect(outcome.taken, ['a']);
    expect(outcome.alreadyFiled, isEmpty);
    expect(outcome.filed, isEmpty);
  });
}

class _FakeScreenshots implements ScreenshotRepository {
  final List<ScreenshotEntity> library;
  final Map<String, String> ocr;

  _FakeScreenshots({required this.library, Map<String, String>? ocr})
    : ocr = {...?ocr};

  @override
  Future<List<ScreenshotEntity>> getAllScreenshots() async => library;

  @override
  Future<Map<String, String>> getCachedOcrText() async => {...ocr};

  @override
  Future<Map<String, List<String>>> getCachedVisualLabels() async => const {};

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'LibraryInsight reached ${invocation.memberName}, which it should not',
  );
}
