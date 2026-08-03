import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/data/data_sources/rules_local_data_source.dart';
import 'package:shoto/features/rules/domain/entities/rule_run_result.dart';
import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Applies the user's rules to what SHOTO knows about a screenshot.
///
/// Depends on [ScreenshotRepository] rather than reaching into the
/// screenshots feature's data sources, the same way the duplicates feature
/// does.
///
/// The two entry points spend effort very differently, on purpose:
///
/// [applyRulesTo] is one screenshot that just arrived, so it *will* run OCR
/// and the vision model if nothing is cached — otherwise a fresh import
/// could never trigger a rule, which is the exact moment the feature is for.
/// The cost is bounded and paid while the user is already waiting on a save,
/// and the results are cached, so search gets them for free afterwards.
///
/// [runRulesOnLibrary] is the backlog, where the same choice would mean
/// recognising an entire library in one tap. It reads caches only, and
/// misses whatever hasn't been indexed yet — the honest trade for a pass
/// that finishes.
class RulesRepositoryImpl implements RulesRepository {
  final RulesLocalDataSource _local;
  final ScreenshotRepository _screenshots;

  RulesRepositoryImpl(this._local, this._screenshots);

  @override
  Future<List<FilingRule>> getRules() => _local.getRules();

  @override
  Future<FilingRule> createRule({
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  }) {
    return _local.createRule(
      name: name,
      folderId: folderId,
      conditions: conditions,
      match: match,
    );
  }

  @override
  Future<void> updateRule({
    required int ruleId,
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  }) {
    return _local.updateRule(
      ruleId: ruleId,
      name: name,
      folderId: folderId,
      conditions: conditions,
      match: match,
    );
  }

  @override
  Future<void> reorderRules(List<int> orderedIds) =>
      _local.reorderRules(orderedIds);

  @override
  Future<void> setRuleEnabled(int ruleId, bool isEnabled) =>
      _local.setEnabled(ruleId, isEnabled);

  @override
  Future<void> deleteRule(int ruleId) => _local.deleteRule(ruleId);

  @override
  Future<int?> applyRulesTo(String assetId) async {
    final List<FilingRule> rules = await _local.getRules();
    if (rules.isEmpty) return null;

    // The one place recognition is allowed to run on demand.
    //
    // A screenshot that just arrived has nothing cached about it yet, so
    // matching on the caches alone would mean a brand-new import never
    // triggers a rule — the exact moment the whole feature is supposed to
    // work. One screenshot is a bounded cost, and it is paid while the user
    // is already waiting for the save to finish.
    final ScreenshotFacts facts = await _extractFactsFor(assetId);

    // First match wins when several rules want the same screenshot, and the
    // list comes back in the user's own priority order. A screenshot can only
    // live in one folder, so *some* tie-break is unavoidable; this is the one
    // they can see and change, because the rules screen lists them in exactly
    // this order, numbered, with arrows to move them.
    final FilingRule? winner = FilingRules.winner(rules, facts);
    if (winner == null) return null;

    await _screenshots.assignFolder([assetId], winner.folderId);
    return winner.folderId;
  }

  /// How many unindexed screenshots one backlog run is allowed to read.
  ///
  /// Recognition is the expensive part — OCR plus, when needed, two vision
  /// passes. Forty is a few seconds of work, which is what somebody who just
  /// tapped a button will wait through; four hundred is not.
  static const int _recognitionBudget = 40;

  @override
  Future<RuleRunResult> runRulesOnLibrary({
    void Function(int processed, int total)? onProgress,
  }) async {
    final List<FilingRule> rules = await _local.getRules();
    if (rules.isEmpty) return RuleRunResult.none;

    final List<ScreenshotEntity> all = await _screenshots.getAllScreenshots();
    final List<ScreenshotEntity> unfiled = all
        .where((screenshot) => screenshot.folderId == null)
        .toList();
    if (unfiled.isEmpty) return RuleRunResult.none;

    // Both caches read once for the whole run rather than per screenshot —
    // they are full-table reads, and doing one per item turned a 200-item
    // library into 400 queries.
    final Map<String, String> ocr = await _screenshots.getCachedOcrText();
    final Map<String, List<String>> labels = await _screenshots
        .getCachedVisualLabels();

    int filed = 0;
    int recognised = 0;
    int unread = 0;
    for (int i = 0; i < unfiled.length; i++) {
      final ScreenshotEntity screenshot = unfiled[i];

      // Read on demand for screenshots nothing is known about yet, up to a
      // budget.
      //
      // This pass used to consult the caches and nothing else, which was the
      // right call when the caches were populated — but it made "Run rules
      // now" do visibly nothing on a library that had never been indexed, and
      // "I pressed the button and nothing happened" is indistinguishable from
      // a broken feature. It also matters more since the labeler learned to
      // ignore medium labels: every row whose only label was "Screenshot" now
      // correctly reads as unindexed, and something has to index it.
      //
      // Bounded rather than unlimited because recognising a whole library in
      // one tap is minutes of work behind a spinner. Anything past the budget
      // still gets matched on whatever is cached, and the next run continues
      // where this one stopped — the pass always finishes.
      final bool known =
          (ocr[screenshot.id]?.isNotEmpty ?? false) ||
          (labels[screenshot.id]?.isNotEmpty ?? false);

      ScreenshotFacts facts;
      if (!known && recognised < _recognitionBudget) {
        recognised++;
        facts = await _extractFactsFor(screenshot.id);
      } else {
        // Counted, not swallowed. Past the budget these are matched against
        // an empty set of facts, so they can only ever come back "no rule
        // wanted this" — which is indistinguishable, in the result line, from
        // a rule that is wrong. The caller says so instead.
        if (!known) unread++;
        facts = await _factsFor(screenshot.id, ocr, labels);
      }

      final FilingRule? winner = FilingRules.winner(rules, facts);
      if (winner != null) {
        await _screenshots.assignFolder([screenshot.id], winner.folderId);
        filed++;
      }
      onProgress?.call(i + 1, unfiled.length);
    }

    return RuleRunResult(
      examined: unfiled.length,
      filed: filed,
      unread: unread,
    );
  }

  Future<ScreenshotFacts> _factsFor(
    String assetId,
    Map<String, String> ocr,
    Map<String, List<String>> labels,
  ) async {
    return ScreenshotFacts.from(
      text: ocr[assetId] ?? '',
      labels: labels[assetId] ?? const [],
    );
  }

  /// Reads a single screenshot properly, running OCR and the vision model
  /// only for what isn't cached yet — and caching the result, so search and
  /// the next rule run both get it for free.
  ///
  /// Falls back to whatever it managed to gather if recognition fails: a
  /// screenshot that can't be read is one no rule matches, which is where
  /// the app already was, not an error worth surfacing mid-save.
  Future<ScreenshotFacts> _extractFactsFor(String assetId) async {
    final List<ScreenshotEntity> found = await _screenshots.getScreenshotsByIds(
      [assetId],
    );
    if (found.isEmpty) return const ScreenshotFacts();
    final ScreenshotEntity screenshot = found.first;

    String text = (await _screenshots.getCachedOcrText())[assetId] ?? '';
    List<String> labels =
        (await _screenshots.getCachedVisualLabels())[assetId] ?? const [];

    try {
      if (text.isEmpty) {
        text = await _screenshots.extractAndCacheText(screenshot);
      }
      if (labels.isEmpty) {
        labels = await _screenshots.extractAndCacheLabels(screenshot);
      }
    } catch (_) {
      // Keep whatever was gathered before the failure.
    }

    return ScreenshotFacts.from(text: text, labels: labels);
  }
}
