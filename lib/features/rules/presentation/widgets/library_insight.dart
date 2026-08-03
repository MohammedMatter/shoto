import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// What SHOTO already knows about the user's own library, so the rules screens
/// can stop asking people to guess.
///
/// This exists because of a specific, avoidable failure. Somebody typed
/// "animal" into "shows something", saved the rule, shared a screenshot of a
/// dog, and nothing happened — so the whole feature read as broken. It wasn't
/// exactly broken; it was **blind**. The builder asked for a word without
/// ever showing which words the vision model actually produces, and there is
/// no way to guess that from the outside.
///
/// Everything here is drawn from the user's real data rather than from a
/// hard-coded list:
///
/// * [subjects] — the words the model has genuinely emitted for *their*
///   screenshots. A rule built by tapping one of these cannot silently
///   fail to match on vocabulary grounds.
/// * [matching] — the actual screenshots a rule would claim, not just how
///   many. A count can be doubted; six thumbnails of the wrong thing cannot.
/// * [outcomeOf] — what would happen once the *other* rules have had their
///   say, because a rule that matches forty screenshots and files none of
///   them is the single most confusing state this feature has.
///
/// Loaded once and passed down, rather than fetched per screen: it is two
/// full-table reads, and the rules page and the builder both want the same
/// answer at the same moment.
class LibraryInsight {
  /// The labels present in the library, most common first.
  final List<String> subjects;

  /// Cached facts per screenshot, reused so the screens read the database
  /// once rather than on every keystroke.
  final Map<String, ScreenshotFacts> _facts;

  /// The screenshots that are not in a folder yet — the only ones a rule run
  /// is allowed to move.
  ///
  /// Needed because "matches this rule" and "this rule will file it" are not
  /// the same set, and the gap between them was being reported as if it were
  /// zero. [runRulesOnLibrary] deliberately skips anything already filed —
  /// re-filing what somebody placed by hand is the failure that killed
  /// automatic albums — so a matching screenshot that already lives in
  /// another folder will never move, no matter how many times the rule runs.
  final Set<String> _unfiled;

  const LibraryInsight._(this.subjects, this._facts, this._unfiled);

  /// Shown while the real thing loads — an empty shortlist and a zero count
  /// read the same as "nothing to suggest yet", which is true at that moment.
  static const LibraryInsight empty = LibraryInsight._([], {}, {});

  /// How many screenshots SHOTO has actually read. Every count below is out
  /// of this, not out of the whole library, and the UI says so.
  int get indexedCount => _facts.length;

  static Future<LibraryInsight> load(ScreenshotRepository repository) async {
    final Map<String, String> ocr = await repository.getCachedOcrText();
    final Map<String, List<String>> labels = await repository
        .getCachedVisualLabels();

    // Counted rather than collected into a set: the order matters. Showing
    // the label that appears on forty screenshots above one that appeared
    // once is the difference between a useful shortlist and a word cloud.
    final Map<String, int> frequency = {};
    for (final List<String> forOne in labels.values) {
      for (final String label in VisualVocabulary.meaningful(forOne)) {
        frequency[label] = (frequency[label] ?? 0) + 1;
      }
    }

    final List<String> subjects = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

    // Union of both caches: a screenshot may have text but no labels, or the
    // other way round, and either is enough for some rules to match on.
    final Map<String, ScreenshotFacts> facts = {};
    for (final String id in {...ocr.keys, ...labels.keys}) {
      facts[id] = ScreenshotFacts.from(
        text: ocr[id] ?? '',
        labels: labels[id] ?? const [],
      );
    }

    return LibraryInsight._(subjects, facts, {
      for (final ScreenshotEntity screenshot
          in await repository.getAllScreenshots())
        if (screenshot.folderId == null) screenshot.id,
    });
  }

  /// The already-indexed screenshots a rule with these conditions would claim.
  ///
  /// Covers only what has been read before — a screenshot nobody has opened
  /// or filed has no cached text or labels yet — so this is a **floor**, not
  /// a prediction. That is the honest number to show: it can only understate
  /// what the rule will do, never oversell it, and every string built from it
  /// says "of the ones SHOTO has read" rather than "of your screenshots".
  List<String> matching(List<RuleCondition> conditions, RuleMatch match) {
    if (conditions.isEmpty) return const [];

    final FilingRule probe = FilingRule(
      id: 0,
      name: '',
      folderId: 0,
      conditions: conditions,
      match: match,
    );
    return [
      for (final MapEntry<String, ScreenshotFacts> entry in _facts.entries)
        if (FilingRules.matches(probe, entry.value)) entry.key,
    ];
  }

  /// What a rule would actually do once the rules above it have taken theirs.
  ///
  /// The gap between "matches" and "files" is the feature's worst silent
  /// failure. A perfectly correct rule can match forty screenshots and file
  /// none, because an enabled rule with higher priority claims all forty
  /// first — and until now nothing anywhere said so. The user sees their rule
  /// do nothing and concludes the rule is wrong, when the rule is right and
  /// only the order is not what they wanted.
  ///
  /// [higherPriority] is the enabled rules ranked above this one, in order.
  RuleOutcome outcomeOf(
    List<RuleCondition> conditions,
    RuleMatch match, {
    required List<FilingRule> higherPriority,
  }) {
    final List<String> claimed = matching(conditions, match);

    final List<String> taken = [
      for (final String id in claimed)
        if (higherPriority.any((rule) => FilingRules.matches(rule, _facts[id]!)))
          id,
    ];

    return RuleOutcome(
      matched: claimed,
      taken: taken,
      // Matched, not outranked, and already sitting in a folder — so a run
      // will pass straight over it. Reported rather than quietly folded into
      // the total, because the two look identical from the outside: a rule
      // that says "claims 1" and files nothing, forever, reads as broken.
      alreadyFiled: [
        for (final String id in claimed)
          if (!taken.contains(id) && !_unfiled.contains(id)) id,
      ],
    );
  }
}

/// A rule's matches split by what actually becomes of them.
///
/// Three groups, because "this rule matches N screenshots" turned out to be
/// three different claims wearing one number, and two of them mean the rule
/// will do nothing:
///
/// * [taken] — a higher-priority rule gets there first.
/// * [alreadyFiled] — the screenshot is in a folder already, and a run never
///   moves those.
/// * [filed] — what is actually left.
class RuleOutcome {
  /// Every indexed screenshot the rule's own conditions accept.
  final List<String> matched;

  /// The subset a higher-priority rule files somewhere else first.
  final List<String> taken;

  /// The subset that already lives in a folder, so no run will move it.
  final List<String> alreadyFiled;

  const RuleOutcome({
    required this.matched,
    required this.taken,
    this.alreadyFiled = const [],
  });

  /// The ones this rule would really end up with — the number worth showing
  /// next to the folder it files into.
  List<String> get filed => [
    for (final String id in matched)
      if (!taken.contains(id) && !alreadyFiled.contains(id)) id,
  ];

  bool get isFullyTaken => matched.isNotEmpty && taken.length == matched.length;

  /// Matches that exist but that nothing will ever act on. The state the
  /// user reads as "my rule does not work".
  bool get isFullyInert => matched.isNotEmpty && filed.isEmpty;
}
