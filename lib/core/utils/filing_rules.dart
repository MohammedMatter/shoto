import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/core/utils/word_match.dart';

/// Decides which of a person's own filing rules a screenshot satisfies.
///
/// SHOTO tried automatic filing once before, as Smart Albums, and it was
/// deleted — not because the classifier was bad, but because it was a guess
/// the user could not inspect. Screenshots landed in the wrong album and
/// there was no answer to "why did it do that", so the whole feature stopped
/// being trustworthy.
///
/// This is the same automation with the authorship reversed. The user writes
/// the rule, in their own words, out of conditions they picked; the app only
/// checks it. Every filing decision has an explanation that already existed
/// before the screenshot did, which is exactly the property the old feature
/// lacked. It is also why this engine deliberately has **no** scoring, no
/// thresholds and no fuzzy matching beyond what the user can predict — a
/// rule that "mostly" matches is a rule nobody can reason about.
///
/// Pure Dart, no Flutter imports, so all of it is unit-testable — the same
/// split used by [PerceptualHash], [ScrollStitcher] and [VisualVocabulary].
class FilingRules {
  const FilingRules._();

  /// The rule that actually files [facts], or null if none wants it.
  ///
  /// [rules] must be in the user's priority order, and the first match wins.
  /// A screenshot lives in exactly one folder, so with two matching rules
  /// something has to break the tie — this is the only place that decides it,
  /// rather than a `.first` written out at each call site, because the answer
  /// has to be the same one the rules screen shows and the builder previews.
  static FilingRule? winner(List<FilingRule> rules, ScreenshotFacts facts) {
    for (final FilingRule rule in rules) {
      if (rule.isEnabled && matches(rule, facts)) return rule;
    }
    return null;
  }

  static bool matches(FilingRule rule, ScreenshotFacts facts) {
    // A rule with no conditions matches nothing. The alternative — matching
    // everything — turns a half-built rule into one that swallows the whole
    // library the moment it is saved.
    if (rule.conditions.isEmpty) return false;

    return switch (rule.match) {
      RuleMatch.all => rule.conditions.every((c) => _test(c, facts)),
      RuleMatch.any => rule.conditions.any((c) => _test(c, facts)),
    };
  }

  static bool _test(RuleCondition condition, ScreenshotFacts facts) {
    final bool held = _holds(condition, facts);
    return condition.isNegated ? !held : held;
  }

  static bool _holds(RuleCondition condition, ScreenshotFacts facts) {
    switch (condition.type) {
      case ConditionType.textContains:
        // Whole words, not substrings — see [WordMatch]. A plain `contains`
        // read "code" out of "barcode" and "total" out of "totally", and a
        // rule that fires for a reason the user cannot see on screen is the
        // exact defect this engine was written to avoid.
        //
        // Normalized on both sides in there too, so a rule written "فاتورة"
        // still fires on a screenshot whose OCR read "فاتوره". Every Arabic
        // feature in this app has needed that pass.
        return WordMatch.contains(facts.text, condition.value);

      case ConditionType.showsSubject:
        // The strict question, not the search one — see
        // [VisualVocabulary.describes]. Search matches by prefix so that
        // half-typed words find things, which also means "category" starts
        // with "cat"; harmless in a result list you can scroll past, not
        // harmless when it silently moves a photo into the wrong folder.
        return VisualVocabulary.describes(facts.labels, condition.value);

      case ConditionType.containsSensitive:
        final SensitiveKind? kind = _sensitiveKindFor(condition.value);
        return kind != null && facts.sensitiveKinds.contains(kind);

      case ConditionType.hasAnyText:
        return facts.text.trim().isNotEmpty;
    }
  }

  static SensitiveKind? _sensitiveKindFor(String value) {
    for (final SensitiveKind kind in SensitiveKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }
}

/// What a rule can ask about a screenshot.
///
/// Deliberately short. Each entry is something the app already knows how to
/// determine reliably and the user can predict the meaning of; an option
/// nobody can predict makes every rule containing it untrustworthy.
enum ConditionType {
  /// Words printed inside the image, via OCR.
  textContains,

  /// What the picture shows, via the on-device vision model.
  showsSubject,

  /// A card number, IBAN, verification code and so on — checksum-backed,
  /// the same detection Safe Share uses.
  containsSensitive,

  /// Any readable text at all. Separates documents from photos.
  hasAnyText,
}

enum RuleMatch { all, any }

class RuleCondition {
  final ConditionType type;

  /// The word, subject or [SensitiveKind.name] being asked about. Unused by
  /// [ConditionType.hasAnyText].
  final String value;

  /// Inverts the condition — "does *not* contain", which is often the only
  /// way to say what you mean ("receipts, but not the ones from work").
  final bool isNegated;

  const RuleCondition({
    required this.type,
    this.value = '',
    this.isNegated = false,
  });
}

class FilingRule {
  final int id;
  final String name;

  /// Where a matching screenshot goes.
  final int folderId;
  final List<RuleCondition> conditions;
  final RuleMatch match;
  final bool isEnabled;

  const FilingRule({
    required this.id,
    required this.name,
    required this.folderId,
    required this.conditions,
    this.match = RuleMatch.all,
    this.isEnabled = true,
  });
}

/// Everything the engine is allowed to look at.
///
/// Passed in rather than fetched, so evaluation stays synchronous and pure —
/// and so the caller controls the cost. All three are already cached by
/// other features; a rule run should never trigger fresh OCR on its own.
class ScreenshotFacts {
  final String text;
  final List<String> labels;
  final Set<SensitiveKind> sensitiveKinds;

  const ScreenshotFacts({
    this.text = '',
    this.labels = const [],
    this.sensitiveKinds = const {},
  });

  /// Derives the sensitive kinds from [text] rather than taking them, for
  /// callers that have not run that detection separately.
  factory ScreenshotFacts.from({
    String text = '',
    List<String> labels = const [],
  }) {
    return ScreenshotFacts(
      text: text,
      labels: labels,
      sensitiveKinds: text.trim().isEmpty
          ? const {}
          : SensitiveData.kindsIn(text),
    );
  }
}
