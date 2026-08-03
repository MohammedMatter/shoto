import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/core/utils/sensitive_data.dart';

/// A rule somebody could plausibly want, ready to save once a folder is
/// picked.
///
/// The rule builder is not hard, but it is *blank*, and a blank builder asks
/// the user to invent both the idea and the syntax at the same time. Almost
/// nobody's first thought is "I would like screenshots containing a Luhn-valid
/// card number filed into Receipts" — but shown that sentence, everybody
/// recognises it and can edit it.
///
/// So these exist to be **read and then changed**, not to be a menu of canned
/// features. Tapping one opens the builder pre-filled, with every condition
/// still removable.
class RuleTemplate {
  final IconData icon;
  final String Function(BuildContext) title;
  final String Function(BuildContext) rationale;
  final List<RuleCondition> conditions;
  final RuleMatch match;

  const RuleTemplate({
    required this.icon,
    required this.title,
    required this.rationale,
    required this.conditions,
    required this.match,
  });

  static List<RuleTemplate> all = [
    RuleTemplate(
      icon: Icons.receipt_long_rounded,
      title: (context) => context.l10n.rulesTemplateReceipts,
      rationale: (context) => context.l10n.rulesTemplateReceiptsWhy,
      // "any" rather than "all": a receipt photographed off a screen may show
      // the total without a card number, and a payment confirmation may show
      // the card without the word. Requiring both would file almost nothing,
      // which is the failure mode people blame on the app rather than on
      // their rule.
      match: RuleMatch.any,
      conditions: const [
        RuleCondition(type: ConditionType.containsSensitive, value: 'card'),
        RuleCondition(type: ConditionType.textContains, value: 'total'),
        RuleCondition(type: ConditionType.textContains, value: 'invoice'),
      ],
    ),

    RuleTemplate(
      icon: Icons.confirmation_number_rounded,
      title: (context) => context.l10n.rulesTemplateTickets,
      rationale: (context) => context.l10n.rulesTemplateTicketsWhy,
      match: RuleMatch.any,
      conditions: const [
        RuleCondition(type: ConditionType.textContains, value: 'boarding'),
        RuleCondition(type: ConditionType.textContains, value: 'ticket'),
        RuleCondition(type: ConditionType.textContains, value: 'booking'),
      ],
    ),

    RuleTemplate(
      icon: Icons.password_rounded,
      title: (context) => context.l10n.rulesTemplateCodes,
      rationale: (context) => context.l10n.rulesTemplateCodesWhy,
      match: RuleMatch.any,
      conditions: const [
        RuleCondition(type: ConditionType.containsSensitive, value: 'code'),
        RuleCondition(type: ConditionType.textContains, value: 'password'),
      ],
    ),

    // Deliberately the odd one out. Every template above matches on words, so
    // without this nobody would discover that SHOTO can also file on what a
    // picture *shows* — and that is the condition that handles the saved
    // photos with no useful text at all.
    RuleTemplate(
      icon: Icons.pets_rounded,
      title: (context) => context.l10n.rulesTemplateAnimals,
      rationale: (context) => context.l10n.rulesTemplateAnimalsWhy,
      match: RuleMatch.any,
      conditions: const [
        RuleCondition(type: ConditionType.showsSubject, value: 'animal'),
        RuleCondition(type: ConditionType.showsSubject, value: 'cat'),
        RuleCondition(type: ConditionType.showsSubject, value: 'dog'),
      ],
    ),
  ];

  /// Guards against a template naming a sensitive kind that later gets
  /// renamed or removed — the value is a string on the way into the database,
  /// so nothing else would catch it.
  static bool isValid(RuleTemplate template) {
    return template.conditions.every((condition) {
      if (condition.type != ConditionType.containsSensitive) return true;
      return SensitiveKind.values.any((kind) => kind.name == condition.value);
    });
  }
}
