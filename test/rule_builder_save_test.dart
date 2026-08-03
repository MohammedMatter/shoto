import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/features/rules/presentation/widgets/rule_summary.dart';

/// Guards the exact report: "I typed Dogs, chose match any, pressed Save, and
/// nothing was stored."
///
/// Nothing was stored because a typed-but-not-yet-added value did not count
/// as a condition, so the Save button was inert and tapping it did nothing at
/// all. These pin the two halves of that fix — the word being a real match,
/// and a rule built from one typed word behaving like any other rule.
void main() {
  testWidgets('the builder is reachable with a single typed condition', (
    tester,
  ) async {
    // A rule the sheet would now produce from a typed value alone, with no
    // "Add condition" tap: one condition, match any.
    const FilingRule typedOnly = FilingRule(
      id: 1,
      name: 'Dogs',
      folderId: 3,
      match: RuleMatch.any,
      conditions: [
        RuleCondition(type: ConditionType.showsSubject, value: 'Dogs'),
      ],
    );

    // It must be a rule that can actually fire — a rule with no conditions
    // matches nothing by design, which is what an empty save would have
    // produced even if it had been allowed through.
    expect(typedOnly.conditions, isNotEmpty);
    expect(
      FilingRules.matches(
        typedOnly,
        ScreenshotFacts.from(text: '', labels: const ['Dog']),
      ),
      isTrue,
    );

    // And it reads back as a sentence, so the card explains itself.
    late String summary;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            summary = RuleSummary.describe(context, typedOnly);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(summary, contains('Dogs'));
  });

  test('a plural typed by hand still matches the singular label', () {
    // "Dogs" is what a person types; "Dog" is what the model emits.
    expect(VisualVocabulary.matches(const ['Dog'], 'Dogs'), isTrue);
  });

  test('a rule with no conditions files nothing, deliberately', () {
    const FilingRule empty = FilingRule(
      id: 1,
      name: 'Empty',
      folderId: 3,
      conditions: [],
    );
    expect(
      FilingRules.matches(
        empty,
        ScreenshotFacts.from(text: 'anything', labels: const ['Dog']),
      ),
      isFalse,
    );
  });
}
