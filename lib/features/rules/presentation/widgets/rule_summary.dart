import 'package:flutter/widgets.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/utils/filing_rules.dart';

/// Says what a rule does, in the sentence a person would have said.
///
/// This is not decoration. The whole reason automatic filing is trustworthy
/// this time is that the user can see the reasoning — so the rule has to be
/// readable everywhere it appears, not just inside the editor that built it.
/// A row that showed only a name would be back to "SHOTO moved my screenshot
/// and I don't know why".
///
/// Every method takes a [BuildContext] because the sentence is translated,
/// and a rule explained in a language the reader does not speak explains
/// nothing at all.
///
/// The negated forms are separate strings rather than a "not " prefix glued
/// on: languages disagree about where negation goes, and in Arabic it changes
/// the verb rather than sitting in front of it.
class RuleSummary {
  const RuleSummary._();

  static String describe(BuildContext context, FilingRule rule) {
    if (rule.conditions.isEmpty) return context.l10n.ruleSummaryEmpty;

    final String joiner = rule.match == RuleMatch.all
        ? context.l10n.ruleJoinAnd
        : context.l10n.ruleJoinOr;
    return rule.conditions
        .map((condition) => describeCondition(context, condition))
        .join(joiner);
  }

  static String describeCondition(
    BuildContext context,
    RuleCondition condition,
  ) {
    final bool no = condition.isNegated;

    return switch (condition.type) {
      ConditionType.textContains =>
        no
            ? context.l10n.ruleNotSaysWord(condition.value)
            : context.l10n.ruleSaysWord(condition.value),
      ConditionType.showsSubject =>
        no
            ? context.l10n.ruleNotShows(condition.value)
            : context.l10n.ruleShows(condition.value),
      ConditionType.containsSensitive =>
        no
            ? context.l10n.ruleNotContains(_kind(context, condition.value))
            : context.l10n.ruleContains(_kind(context, condition.value)),
      ConditionType.hasAnyText =>
        no ? context.l10n.ruleNoText : context.l10n.ruleHasText,
    };
  }

  /// Falls through to the raw stored value for anything unrecognised — a rule
  /// written by an older version must still read as *something* rather than
  /// crashing or showing a blank.
  static String _kind(BuildContext context, String value) {
    return switch (value) {
      'card' => context.l10n.kindCard,
      'iban' => context.l10n.kindIban,
      'code' => context.l10n.kindCode,
      'nationalId' => context.l10n.kindNationalId,
      'email' => context.l10n.kindEmail,
      'phone' => context.l10n.kindPhone,
      _ => value,
    };
  }
}
