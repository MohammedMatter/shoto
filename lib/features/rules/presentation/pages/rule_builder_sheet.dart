import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/library_indexer.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/rules/presentation/widgets/library_insight.dart';
import 'package:shoto/features/rules/presentation/widgets/rule_summary.dart';
import 'package:shoto/features/rules/presentation/widgets/rule_templates.dart';

/// What the user typed, once they're happy with it.
class RuleDraft {
  /// The rule being rewritten, or null when this is a new one. Carried back
  /// out so the caller updates in place instead of deleting and recreating —
  /// which would silently drop the rule's priority and its on/off switch.
  final int? ruleId;

  final String name;
  final int folderId;
  final List<RuleCondition> conditions;
  final RuleMatch match;

  const RuleDraft({
    required this.name,
    required this.folderId,
    required this.conditions,
    required this.match,
    this.ruleId,
  });

  bool get isEdit => ruleId != null;
}

/// Builds a filing rule by assembling conditions rather than typing a query.
///
/// A text box would have been far less code and much worse: a query language
/// has to be learned, mistyped and debugged, and a rule you're unsure you
/// wrote correctly is one you won't trust to move your files. Picking from
/// what the app can actually check means every rule is valid by construction,
/// and the plain-English summary at the bottom is the proof.
///
/// [existing] opens the sheet on a rule the user already has, for editing.
/// [higherPriority] is the enabled rules ranked above this one; the preview
/// needs them to say what this rule would *actually* file rather than only
/// what it matches.
Future<RuleDraft?> showRuleBuilderSheet(
  BuildContext context, {
  required List<FolderEntity> folders,
  RuleTemplate? template,
  FilingRule? existing,
  List<FilingRule> higherPriority = const [],
}) {
  return showAppSheet<RuleDraft>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RuleBuilderSheet(
      folders: folders,
      template: template,
      existing: existing,
      higherPriority: higherPriority,
    ),
  );
}

class _RuleBuilderSheet extends StatefulWidget {
  final List<FolderEntity> folders;

  /// An example to open pre-filled, or null for a blank rule.
  final RuleTemplate? template;

  /// The rule being edited, or null when writing a new one.
  final FilingRule? existing;

  /// The enabled rules that outrank this one, in priority order.
  final List<FilingRule> higherPriority;

  const _RuleBuilderSheet({
    required this.folders,
    required this.higherPriority,
    this.template,
    this.existing,
  });

  @override
  State<_RuleBuilderSheet> createState() => _RuleBuilderSheetState();
}

class _RuleBuilderSheetState extends State<_RuleBuilderSheet> {
  final TextEditingController _valueController = TextEditingController();

  ConditionType _draftType = ConditionType.textContains;
  String _draftSensitive = SensitiveKind.card.name;
  bool _draftNegated = false;

  final List<RuleCondition> _conditions = [];
  RuleMatch _match = RuleMatch.all;
  FolderEntity? _folder;

  /// What the app has already read out of this user's screenshots.
  ///
  /// Loaded once, in the background, and the sheet is fully usable before it
  /// arrives — everything it feeds is help, not a requirement.
  LibraryInsight _insight = LibraryInsight.empty;

  late final LibraryIndexer _indexer = sl<LibraryIndexer>();
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _prefill();
    _indexer.addListener(_onIndexerChanged);
    unawaited(_loadInsight());
  }

  /// Keeps the preview honest while the library is still being read.
  ///
  /// This sheet is where somebody decides whether their rule works, and it
  /// decides it from a count. If that count is still climbing, the sheet has
  /// to both say so and *keep up* — a preview frozen at "matches 2" while the
  /// indexer is finding the other forty is worse than no preview at all.
  void _onIndexerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_reloadTimer?.isActive ?? false) return;
    _reloadTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(_loadInsight()),
    );
  }

  Future<void> _loadInsight() async {
    final LibraryInsight insight = await LibraryInsight.load(
      sl<ScreenshotRepository>(),
    );
    if (mounted) setState(() => _insight = insight);
  }

  /// Opens the sheet on an existing rule, or on an example.
  ///
  /// This used to live in `didChangeDependencies`, because it read the
  /// template's **translated** title to prefill the name field, and reading a
  /// translation during `initState` throws — the element is not yet attached
  /// to the tree that would provide it. With the name field gone (see
  /// [_saveName]) nothing here touches localization any more, so it belongs
  /// back in `initState` where prefill obviously happens once.
  void _prefill() {
    final FilingRule? existing = widget.existing;
    if (existing != null) {
      _conditions.addAll(existing.conditions);
      _match = existing.match;
      // firstWhereOrNull by hand: the rule's folder can be missing from the
      // list if it was deleted between this sheet opening and the folders
      // being read, and an exception here would take down the only screen
      // where the rule could be pointed somewhere else.
      for (final FolderEntity folder in widget.folders) {
        if (folder.id == existing.folderId) _folder = folder;
      }
      return;
    }

    final RuleTemplate? template = widget.template;
    if (template == null) return;

    // Everything except the folder, which is the one thing only the user can
    // answer — and leaving exactly one blank is what turns an example into
    // something they finish rather than something they just read.
    _conditions.addAll(template.conditions);
    _match = template.match;
  }

  bool get _needsValue =>
      _draftType == ConditionType.textContains ||
      _draftType == ConditionType.showsSubject;

  bool get _canAddCondition =>
      !_needsValue || _valueController.text.trim().isNotEmpty;

  /// The condition currently being typed, if it is already complete.
  ///
  /// This exists because of a real report: somebody typed `Dogs`, chose
  /// "match any", pressed Save — and nothing happened. The value was sitting
  /// on screen, so of course they expected it to count; but it only became
  /// part of the rule after a separate "Add condition" tap, and without it
  /// `_conditions` was empty, the Save button was inert, and pressing it did
  /// nothing at all. A disabled button teaches nobody anything.
  ///
  /// Treating a filled-in draft as part of the rule makes the extra tap
  /// optional rather than load-bearing. "Add condition" still exists, and is
  /// still the only way to reach a *second* condition — it just stops being a
  /// trap on the way to the first.
  RuleCondition? get _pendingCondition {
    if (!_canAddCondition) return null;
    return RuleCondition(
      type: _draftType,
      value: switch (_draftType) {
        ConditionType.containsSensitive => _draftSensitive,
        ConditionType.hasAnyText => '',
        _ => _valueController.text.trim(),
      },
      isNegated: _draftNegated,
    );
  }

  /// What this rule would actually be saved with: the committed conditions
  /// plus whatever is still in the draft row. Everything the sheet shows —
  /// the sentence, the match count, the Save button — reads from here, so
  /// what you see is what gets stored.
  List<RuleCondition> get _effectiveConditions => [
    ..._conditions,
    ?_pendingCondition,
  ];

  /// Whether the rule matches anything yet — the gate for revealing step two.
  bool get _hasCondition => _effectiveConditions.isNotEmpty;

  bool get _canSave => _hasCondition && _folder != null;

  /// What the rule gets called, without asking.
  ///
  /// The sheet used to open on a "name it" field, which is the hardest
  /// question in the flow — you have to summarise a rule you have not written
  /// yet — and it was blocking Save until answered. Meanwhile the card on the
  /// rules list already prints the rule as a full sentence underneath the
  /// name, so the name was never carrying the meaning anyway.
  ///
  /// The folder is the honest answer: "Receipts" beside "when it has a card
  /// number on it" reads exactly as somebody would describe the rule out loud.
  /// Two rules into one folder end up sharing a title, which is the one cost —
  /// and the sentence under each still tells them apart.
  String get _saveName => _folder?.name ?? '';

  /// What this rule would do to the library as it stands, after the rules
  /// ranked above it have taken theirs.
  RuleOutcome get _outcome => _insight.outcomeOf(
    _effectiveConditions,
    _match,
    higherPriority: widget.higherPriority,
  );

  @override
  void dispose() {
    _indexer.removeListener(_onIndexerChanged);
    _reloadTimer?.cancel();
    _valueController.dispose();
    super.dispose();
  }

  void _addCondition() {
    final RuleCondition? condition = _pendingCondition;
    if (condition == null) return;

    setState(() {
      // Silently collapsed rather than added twice.
      //
      // Nothing used to stop it, and a real rule ended up reading "when it
      // has a bank account number **or** it has a bank account number". That
      // changes nothing about matching — A or A is A — but it is the sentence
      // the whole feature relies on to be trustworthy, and a rule that reads
      // like a bug is one nobody believes.
      //
      // Clearing the draft either way is what makes it feel like an ordinary
      // "added": the value leaves the field, the chip it would have become is
      // already sitting above it.
      if (!_conditions.any((existing) => _isSame(existing, condition))) {
        _conditions.add(condition);
      }
      _valueController.clear();
      _draftNegated = false;
    });
  }

  static bool _isSame(RuleCondition a, RuleCondition b) =>
      a.type == b.type && a.value == b.value && a.isNegated == b.isNegated;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The gap this sheet leaves at the top of the screen, and the reason it
        // is a widget instead of `Padding`.
        //
        // Padding looks identical and behaves wrongly: the sixty pixels are
        // still *inside* the sheet, so tapping them hit the sheet's own child
        // and nothing happened. Every other sheet in the app closes when you
        // tap beside it — that is Flutter's modal barrier, which this strip was
        // covering. The one sheet tall enough to have a visible gap was the one
        // sheet whose gap did not work.
        //
        // Opaque hit testing, so the tap lands on the empty box rather than
        // falling through to the barrier: either would close the sheet, but only
        // this way is it this widget's stated job.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: SizedBox(height: 60.h),
        ),
        Expanded(
          // Inside the gap, not around it: glass wrapped around that strip would
          // put a pane over the page instead of over the sheet.
          child: SheetSurface(
            child: Column(
              children: [
                Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      20.w,
                      4.h,
                      20.w,
                      20.h + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    children: [
                      Text(
                        widget.existing == null
                            ? context.l10n.ruleBuilderTitle
                            : context.l10n.ruleBuilderEditTitle,
                        style: AppTextStyles.headlineMedium,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        switch (widget) {
                          _ when widget.existing != null =>
                            context.l10n.ruleBuilderEditIntro,
                          _ when widget.template != null =>
                            context.l10n.rulesTemplatePicked,
                          _ => context.l10n.ruleBuilderIntro,
                        },
                        style: AppTextStyles.bodySmall,
                      ),

                      // Step one, and the whole reason this order changed.
                      //
                      // The sheet used to open on "name it". That is the
                      // hardest question in the whole flow and it was being
                      // asked first, before the user had decided what the rule
                      // even does — so the very first thing the feature did was
                      // stop somebody who knew exactly what they wanted. The
                      // name is gone entirely now; see [_saveName].
                      //
                      // What is left runs in the order the finished sentence
                      // reads: what to match, then where it goes.
                      _Label(context.l10n.ruleBuilderConditionLabel),
                      _ConditionTypePicker(
                        value: _draftType,
                        onChanged: (type) => setState(() {
                          _draftType = type;
                          _valueController.clear();
                        }),
                      ),
                      SizedBox(height: 10.h),
                      if (_needsValue)
                        _Field(
                          controller: _valueController,
                          hint: _draftType == ConditionType.textContains
                              ? context.l10n.conditionTextContainsHint
                              : context.l10n.conditionShowsSubjectHint,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _addCondition(),
                        )
                      else if (_draftType == ConditionType.containsSensitive)
                        _SensitivePicker(
                          value: _draftSensitive,
                          onChanged: (value) =>
                              setState(() => _draftSensitive = value),
                        ),
                      if (_draftType == ConditionType.showsSubject)
                        _SubjectSuggestions(
                          subjects: _insight.subjects,
                          onPick: (subject) => setState(() {
                            _valueController.text = subject;
                          }),
                        ),

                      SizedBox(height: 12.h),
                      _PolarityPicker(
                        isNegated: _draftNegated,
                        onChanged: (negated) =>
                            setState(() => _draftNegated = negated),
                      ),

                      // Step two, and only once step one is answerable.
                      //
                      // Everything below here stays hidden until the rule has
                      // something to match, so an untouched sheet is one
                      // question rather than seven. Nothing is removed — it
                      // arrives when it starts to mean something.
                      if (_hasCondition) ...[
                        _Label(context.l10n.ruleBuilderFolderLabel),
                        _FolderPicker(
                          folders: widget.folders,
                          selected: _folder,
                          onSelected: (folder) =>
                              setState(() => _folder = folder),
                        ),

                        // Only the conditions already committed. The one being
                        // edited is the row above, not a chip — showing it in
                        // both places was the sheet describing the same thing
                        // twice.
                        if (_conditions.isNotEmpty) ...[
                          _Label(context.l10n.ruleBuilderConditionsLabel),
                          for (int i = 0; i < _conditions.length; i++)
                            _ConditionChip(
                              text: RuleSummary.describeCondition(
                                context,
                                _conditions[i],
                              ),
                              onRemove: () =>
                                  setState(() => _conditions.removeAt(i)),
                            ),
                        ],

                        // Demoted from a control you meet on the way to your
                        // first condition to one you meet only after you have
                        // one. It used to sit beside the invert checkbox, above
                        // everything, implying the rule was not real until it
                        // was pressed.
                        SizedBox(height: 14.h),
                        _AddButton(
                          enabled: _canAddCondition,
                          onTap: _addCondition,
                        ),

                        if (_effectiveConditions.length > 1) ...[
                          SizedBox(height: 16.h),
                          _MatchPicker(
                            value: _match,
                            onChanged: (m) => setState(() => _match = m),
                          ),
                        ],
                        SizedBox(height: 16.h),
                        // The rule, read back. Nobody should have to run a rule
                        // to find out what they built.
                        _Label(context.l10n.ruleBuilderPreviewTitle),
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            context.l10n.ruleBuilderPreview(
                              _folder?.name ?? '…',
                              RuleSummary.describe(
                                context,
                                FilingRule(
                                  id: 0,
                                  name: '',
                                  folderId: 0,
                                  conditions: _effectiveConditions,
                                  match: _match,
                                ),
                              ),
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // The evidence, under the sentence: what this rule
                        // would take out of the library that already exists.
                        // The sentence says what was written; this says
                        // whether it works, and nobody should have to save a
                        // rule and wait a week to find out.
                        SizedBox(height: 16.h),
                        _Evidence(
                          outcome: _outcome,
                          indexedCount: _insight.indexedCount,
                          indexingLeft: _indexer.isWorking
                              ? _indexer.remaining
                              : 0,
                        ),
                      ],

                      SizedBox(height: 22.h),
                      _SaveButton(
                        enabled: _canSave,
                        isEdit: widget.existing != null,
                        onTap: () => Navigator.of(context).pop(
                          RuleDraft(
                            ruleId: widget.existing?.id,
                            name: _saveName,
                            folderId: _folder!.id,
                            // Includes the draft row — see [_pendingCondition].
                            conditions: List.of(_effectiveConditions),
                            match: _match,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The words the vision model has actually produced for this user's own
/// screenshots, offered as chips.
///
/// The single most important control in this sheet. Nobody can guess a
/// model's vocabulary, and guessing wrong produces a rule that saves fine and
/// then never fires — which reads as the feature being broken rather than as
/// the word being unknown. Tapping a chip makes that impossible.
class _SubjectSuggestions extends StatelessWidget {
  final List<String> subjects;
  final ValueChanged<String> onPick;

  const _SubjectSuggestions({required this.subjects, required this.onPick});

  /// Enough to be representative, few enough to scan. Beyond this the list
  /// stops being a shortlist and becomes another thing to read.
  static const int _limit = 14;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.ruleSeenTitle, style: AppTextStyles.overline),
          SizedBox(height: 8.h),

          if (subjects.isEmpty)
            // Says why the list is empty instead of showing nothing, which
            // would read as one more thing that doesn't work.
            _Help(context.l10n.ruleSeenEmpty)
          else ...[
            Wrap(
              spacing: 7.w,
              runSpacing: 7.h,
              children: [
                for (final String subject in subjects.take(_limit))
                  PressableScale(
                    scale: 0.94,
                    onTap: () => onPick(subject),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 11.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(subject, style: AppTextStyles.caption),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            _Help(context.l10n.ruleSeenHint),
          ],
        ],
      ),
    );
  }
}

/// What this rule would do to the library the user already has.
///
/// A count on its own was not enough, and the reason is specific: the number
/// was right and people still did not believe it, because there was no way to
/// check it. Three failures hid behind one figure — a rule that matches
/// nothing, a rule that matches the wrong pictures, and a rule that matches
/// the right ones but never gets them because another rule outranks it. All
/// three read as "the number is wrong".
///
/// So this shows the count, the actual screenshots behind it, and — when it
/// applies — the fact that something above has already claimed them.
/// Deliberately styled as information rather than a warning even at zero:
/// zero is a legitimate answer for a rule written for screenshots that have
/// not arrived yet.
class _Evidence extends StatelessWidget {
  final RuleOutcome outcome;

  /// How many screenshots SHOTO has read at all. Every count here is out of
  /// this, and saying so is the difference between a floor and a promise.
  final int indexedCount;

  /// Screenshots the indexer has still to read, or 0 when it is done.
  ///
  /// The count above is out of what has been read, so while this is non-zero
  /// every figure here is a floor that is still rising. Saying so is what
  /// stops somebody rewriting a perfectly good rule because it currently
  /// matches two things.
  final int indexingLeft;

  const _Evidence({
    required this.outcome,
    required this.indexedCount,
    required this.indexingLeft,
  });

  @override
  Widget build(BuildContext context) {
    // Nothing has been read yet, so there is no evidence to give and a "0"
    // here would be read as "your rule is broken" rather than "ask me later".
    if (indexedCount == 0) {
      return _Help(
        indexingLeft > 0
            ? context.l10n.indexingProgress(indexingLeft)
            : context.l10n.rulePreviewNotIndexed,
      );
    }

    final List<String> filed = outcome.filed;
    final bool any = filed.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              any ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 14.sp,
              color: any ? AppColors.success : AppColors.textDisabled,
            ),
            SizedBox(width: 7.w),
            Expanded(
              child: Text(
                any
                    ? context.l10n.rulePreviewMatches(filed.length, indexedCount)
                    : context.l10n.rulePreviewNone,
                style: AppTextStyles.caption.asMedium.copyWith(
                  color: any ? AppColors.success : AppColors.textDisabled,
                ),
              ),
            ),
          ],
        ),

        if (any) ...[
          SizedBox(height: 10.h),
          _MatchStrip(assetIds: filed),
        ],

        // Said even when some matches survive: "27 matched, 24 of them go
        // somewhere else" is the state people spend the longest failing to
        // work out on their own.
        if (outcome.taken.isNotEmpty) ...[
          SizedBox(height: 10.h),
          _Warning(
            outcome.isFullyTaken
                ? context.l10n.rulePreviewAllTaken
                : context.l10n.rulePreviewTaken(outcome.taken.length),
          ),
        ],

        // The other way a rule matches things and files none of them, and the
        // one that is impossible to guess: a run only ever touches
        // screenshots that are not in a folder yet, so anything already filed
        // is matched and skipped, every single time.
        if (outcome.alreadyFiled.isNotEmpty) ...[
          SizedBox(height: 10.h),
          _Warning(
            context.l10n.rulePreviewAlreadyFiled(outcome.alreadyFiled.length),
          ),
        ],

        SizedBox(height: 8.h),
        // Two different sentences on purpose. "Still reading, 340 to go" is a
        // reason the number will change; "counts only what has been read" is
        // a standing caveat once it has stopped changing. Showing the caveat
        // during a sweep would understate it, and the sweep line afterwards
        // would be a lie.
        _Help(
          indexingLeft > 0
              ? context.l10n.indexingProgress(indexingLeft)
              : context.l10n.rulePreviewFloor,
        ),
      ],
    );
  }
}

/// The first few screenshots the rule would take, as pictures.
///
/// Loads its own assets and reloads only when the ids actually change, not on
/// every rebuild — the sheet rebuilds on each keystroke, and a `FutureBuilder`
/// built inline would start a fresh gallery read per character typed and
/// flash an empty row between them.
class _MatchStrip extends StatefulWidget {
  final List<String> assetIds;
  const _MatchStrip({required this.assetIds});

  /// Enough to recognise the rule's aim, few enough to stay one row. Past
  /// this the strip stops being a glance and becomes a gallery.
  static const int _limit = 6;

  List<String> get _shown => assetIds.take(_limit).toList();

  @override
  State<_MatchStrip> createState() => _MatchStripState();
}

class _MatchStripState extends State<_MatchStrip> {
  List<ScreenshotEntity> _screenshots = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_MatchStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIds(oldWidget._shown, widget._shown)) _load();
  }

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _load() async {
    final List<String> requested = widget._shown;
    final List<ScreenshotEntity> found = await sl<ScreenshotRepository>()
        .getScreenshotsByIds(requested);
    // A slow read for an older set of ids must not overwrite a newer one —
    // typing quickly starts several of these and nothing guarantees they come
    // back in the order they were asked for.
    if (!mounted || !_sameIds(requested, widget._shown)) return;
    setState(() => _screenshots = found);
  }

  @override
  Widget build(BuildContext context) {
    // Holds its height while the assets load, so the sheet does not jump
    // under the finger between one keystroke and the next.
    return SizedBox(
      height: 62.w,
      child: _screenshots.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _screenshots.length,
              separatorBuilder: (_, _) => SizedBox(width: 7.w),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(11.r),
                child: SizedBox(
                  width: 62.w,
                  height: 62.w,
                  child: AssetThumbnailImage(
                    asset: _screenshots[index].asset,
                  ),
                ),
              ),
            ),
    );
  }
}

/// A note that something will not work the way the sentence above implies.
///
/// Separate from [_Help] rather than a colour parameter on it, because the
/// two say different things: help explains a control, this contradicts what
/// the user just read.
class _Warning extends StatelessWidget {
  final String text;
  const _Warning(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(
              Icons.low_priority_rounded,
              size: 15.sp,
              color: AppColors.warning,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 22.h, bottom: 9.h),
      child: Text(text.toUpperCase(), style: AppTextStyles.overline),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
      ),
    );
  }
}

class _FolderPicker extends StatelessWidget {
  final List<FolderEntity> folders;
  final FolderEntity? selected;
  final ValueChanged<FolderEntity> onSelected;

  const _FolderPicker({
    required this.folders,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final FolderEntity folder in folders)
          _Pill(
            label: folder.name,
            icon: Icons.folder_rounded,
            tint: Color(folder.color),
            selected: selected?.id == folder.id,
            onTap: () => onSelected(folder),
          ),
      ],
    );
  }
}

class _ConditionTypePicker extends StatelessWidget {
  final ConditionType value;
  final ValueChanged<ConditionType> onChanged;

  const _ConditionTypePicker({required this.value, required this.onChanged});

  static IconData _icon(ConditionType type) => switch (type) {
    ConditionType.textContains => Icons.text_fields_rounded,
    ConditionType.showsSubject => Icons.image_search_rounded,
    ConditionType.containsSensitive => Icons.shield_moon_rounded,
    ConditionType.hasAnyText => Icons.notes_rounded,
  };

  static String label(BuildContext context, ConditionType type) =>
      switch (type) {
        ConditionType.textContains => context.l10n.conditionTextContains,
        ConditionType.showsSubject => context.l10n.conditionShowsSubject,
        ConditionType.containsSensitive =>
          context.l10n.conditionContainsSensitive,
        ConditionType.hasAnyText => context.l10n.conditionHasAnyText,
      };

  /// What this condition actually looks at, in one sentence.
  ///
  /// "says a word" and "shows something" sound almost interchangeable until
  /// you know one reads the text and the other reads the picture — and that
  /// distinction is the whole reason both exist.
  static String help(BuildContext context, ConditionType type) =>
      switch (type) {
        ConditionType.textContains => context.l10n.conditionTextContainsHelp,
        ConditionType.showsSubject => context.l10n.conditionShowsSubjectHelp,
        ConditionType.containsSensitive =>
          context.l10n.conditionContainsSensitiveHelp,
        ConditionType.hasAnyText => context.l10n.conditionHasAnyTextHelp,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final ConditionType type in ConditionType.values)
              _Pill(
                label: label(context, type),
                icon: _icon(type),
                selected: value == type,
                onTap: () => onChanged(type),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        // Explains only the selected one. Four explanations at once is a wall
        // of text nobody reads; one that changes as you tap is impossible to
        // miss.
        _Help(help(context, value)),
      ],
    );
  }
}

/// A short note under a control, styled so it reads as guidance rather than
/// as one more thing to press.
class _Help extends StatelessWidget {
  final String text;
  const _Help(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(
            Icons.info_outline_rounded,
            size: 13.sp,
            color: AppColors.textDisabled,
          ),
        ),
        SizedBox(width: 7.w),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _SensitivePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SensitivePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final SensitiveKind kind in SensitiveKind.values)
          _Pill(
            label: kind.label(context),
            icon: Icons.lock_rounded,
            selected: value == kind.name,
            onTap: () => onChanged(kind.name),
          ),
      ],
    );
  }
}

class _MatchPicker extends StatelessWidget {
  final RuleMatch value;
  final ValueChanged<RuleMatch> onChanged;

  const _MatchPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Pill(
              label: context.l10n.ruleBuilderMatchAll,
              icon: Icons.join_inner_rounded,
              selected: value == RuleMatch.all,
              onTap: () => onChanged(RuleMatch.all),
            ),
            SizedBox(width: 8.w),
            _Pill(
              label: context.l10n.ruleBuilderMatchAny,
              icon: Icons.join_full_rounded,
              selected: value == RuleMatch.any,
              onTap: () => onChanged(RuleMatch.any),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // All-versus-any is the one choice here people get wrong silently:
        // the rule saves fine, then files nothing, and nothing on screen
        // says why.
        _Help(
          value == RuleMatch.all
              ? context.l10n.ruleBuilderMatchAllHelp
              : context.l10n.ruleBuilderMatchAnyHelp,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? tint;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = tint ?? AppColors.primary;

    return PressableScale(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        // curve was absent, and AnimatedContainer's default is Curves.linear
        // — so the fill, the border colour and the border width all
        // crossfaded at a constant rate. Linear is for things that genuinely
        // move at a constant rate; a selection changing is not one of them.
        duration: AppMotion.duration(context, AppMotion.press),
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : AppColors.surface,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15.sp,
              color: selected ? accent : AppColors.textSecondary,
            ),
            SizedBox(width: 7.w),
            Text(
              label,
              style: AppTextStyles.bodySmall.asMedium.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether the condition has to be true or has to be false.
///
/// This replaced a checkbox labelled "Invert (does NOT)", which was the single
/// least understandable control in the sheet, for two compounding reasons. A
/// checkbox states only one of its two meanings — the other is "whatever this
/// says, but not" — so reading the rule meant holding a boolean in your head
/// and negating a sentence yourself. And "invert" is a word about the
/// *control* rather than about screenshots.
///
/// Two pills, one always selected, both spelled out. Nothing to remember,
/// because both possible readings are on screen at once — and the words match
/// the summary sentence the rule will be read back in, so choosing one is the
/// same act as reading the result.
class _PolarityPicker extends StatelessWidget {
  final bool isNegated;
  final ValueChanged<bool> onChanged;

  const _PolarityPicker({required this.isNegated, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _Pill(
              label: context.l10n.ruleBuilderMatches,
              icon: Icons.check_rounded,
              selected: !isNegated,
              onTap: () => onChanged(false),
            ),
            _Pill(
              label: context.l10n.ruleBuilderMatchesNot,
              icon: Icons.block_rounded,
              selected: isNegated,
              onTap: () => onChanged(true),
            ),
          ],
        ),
        // Explained only when it is switched on. "Useful for carving out
        // exceptions" is guidance somebody needs at the moment they have
        // chosen the odd option, and clutter every other moment.
        if (isNegated) ...[
          SizedBox(height: 8.h),
          _Help(context.l10n.ruleBuilderMatchesNotHelp),
        ],
      ],
    );
  }
}

/// A condition already committed to the rule.
///
/// There used to be a second, tinted variant for the row still being edited,
/// so a half-typed condition appeared both in its own controls and again as a
/// chip below them. That was the sheet describing one thing twice, and the
/// duplicate is what made the list feel longer than the rule was. The row
/// being edited is now shown only where it is edited.
class _ConditionChip extends StatelessWidget {
  final String text;
  final VoidCallback onRemove;

  const _ConditionChip({required this.text, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 11.h, 6.w, 11.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
          PressableScale(
            scale: 0.85,
            onTap: onRemove,
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.close_rounded,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.95,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: enabled ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16.sp,
              color: enabled ? AppColors.primary : AppColors.textDisabled,
            ),
            SizedBox(width: 6.w),
            Text(
              context.l10n.ruleBuilderAddCondition,
              style: AppTextStyles.bodySmall.asMedium.copyWith(
                color: enabled ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  /// Changes the label to "Save changes". Same button, different promise: on
  /// an existing rule the alternative reads as though a second copy is about
  /// to appear in the list.
  final bool isEdit;

  const _SaveButton({
    required this.enabled,
    required this.onTap,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(17.r),
          border: enabled ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          !enabled
              ? context.l10n.ruleBuilderIncomplete
              : isEdit
              ? context.l10n.ruleBuilderUpdate
              : context.l10n.ruleBuilderSave,
          style: AppTextStyles.button.copyWith(
            color: enabled ? AppColors.onPrimary : AppColors.textDisabled,
            // The incomplete-state label is a whole sentence where the ready
            // state is two words, so it comes down a step to fit the same
            // button. `null` leaves the scale's own size alone — hard-coding
            // it again here is how the two drifted apart in the first place.
            fontSize: enabled ? null : 12.5.sp,
          ),
        ),
      ),
    );
  }
}
