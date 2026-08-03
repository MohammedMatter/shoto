import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/presentation/widgets/rule_summary.dart';

/// The summary is the feature's honesty mechanism — if a rule can't be read
/// back in plain words, the user is trusting filing they can't inspect, which
/// is exactly what got the previous auto-filing deleted.
///
/// These became widget tests when the sentence became translatable: it is now
/// assembled from `AppLocalizations`, which only exists inside a built tree.
/// Worth the extra scaffolding — asserting on the real English output is what
/// catches a phrase that reads wrong, and testing some pre-translation string
/// instead would have stopped testing the thing users actually see.
void main() {
  /// Runs [body] under English localizations and returns what it produced.
  Future<String> summarize(
    WidgetTester tester,
    String Function(BuildContext) body,
  ) async {
    late String result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = body(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('reads back as a sentence', (tester) async {
    const FilingRule rule = FilingRule(
      id: 1,
      name: 'Receipts',
      folderId: 2,
      conditions: [
        RuleCondition(type: ConditionType.textContains, value: 'invoice'),
        RuleCondition(type: ConditionType.containsSensitive, value: 'card'),
      ],
    );
    expect(
      await summarize(tester, (context) => RuleSummary.describe(context, rule)),
      'says "invoice" and contains a card number',
    );
  });

  testWidgets('"any" reads as or', (tester) async {
    const FilingRule rule = FilingRule(
      id: 1,
      name: 'Pets',
      folderId: 2,
      match: RuleMatch.any,
      conditions: [
        RuleCondition(type: ConditionType.showsSubject, value: 'قطة'),
        RuleCondition(type: ConditionType.showsSubject, value: 'كلب'),
      ],
    );
    expect(
      await summarize(tester, (context) => RuleSummary.describe(context, rule)),
      'shows قطة or shows كلب',
    );
  });

  testWidgets('negation reads as a negation', (tester) async {
    const FilingRule rule = FilingRule(
      id: 1,
      name: 'Personal',
      folderId: 2,
      conditions: [
        RuleCondition(
          type: ConditionType.textContains,
          value: 'work',
          isNegated: true,
        ),
      ],
    );
    expect(
      await summarize(tester, (context) => RuleSummary.describe(context, rule)),
      'does not say "work"',
    );
  });

  testWidgets('an empty rule says so rather than pretending', (tester) async {
    const FilingRule rule = FilingRule(
      id: 1,
      name: 'Empty',
      folderId: 2,
      conditions: [],
    );
    expect(
      await summarize(tester, (context) => RuleSummary.describe(context, rule)),
      contains('files nothing'),
    );
  });

  testWidgets('every condition type has a readable form', (tester) async {
    for (final ConditionType type in ConditionType.values) {
      final String text = await summarize(
        tester,
        (context) => RuleSummary.describeCondition(
          context,
          RuleCondition(type: type, value: 'card'),
        ),
      );
      expect(text.trim(), isNotEmpty, reason: type.name);
      expect(text, isNot(contains(type.name)), reason: 'leaked the enum name');
    }
  });
}
