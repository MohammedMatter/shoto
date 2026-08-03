import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/library_indexer.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/app_switch.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/rules/domain/entities/rule_run_result.dart';
import 'package:shoto/features/rules/presentation/bloc/rules_bloc.dart';
import 'package:shoto/features/rules/presentation/bloc/rules_event.dart';
import 'package:shoto/features/rules/presentation/bloc/rules_state.dart';
import 'package:shoto/features/rules/presentation/pages/rule_builder_sheet.dart';
import 'package:shoto/features/rules/presentation/widgets/library_insight.dart';
import 'package:shoto/features/rules/presentation/widgets/rule_summary.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/rules/presentation/widgets/rule_templates.dart';
import 'package:shoto/features/rules/presentation/widgets/rules_explainer.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';

/// Premium-gates then opens [RulesPage], mirroring the search and duplicates
/// gates so entitlement is checked in exactly one shape everywhere.
Future<void> openRulesPage(BuildContext context) async {
  if (!await ensurePremium(context)) return;
  if (!context.mounted) return;

  // Held onto before the push, because this is the last moment [context] is
  // still inside the shell that provides it — the route below is pushed onto
  // the root navigator and is deliberately not a descendant.
  final ScreenshotsBloc screenshots = context.read<ScreenshotsBloc>();

  await Navigator.of(
    context,
  ).push(FadeSlidePageRoute(builder: (_) => RulesPage()));

  // Running the rules moves screenshots into folders, and the Library tab
  // holds a list loaded before any of that happened. Without this it kept
  // showing "2 unsorted" after a run had just filed one of them — the count
  // was not wrong when it was read, it was simply never read again, and a
  // stale number on the screen that reports what needs doing is worse than
  // no number.
  //
  // Not the gallery-change stream: that watches the device's photo library,
  // and filing only ever writes a row in SHOTO's own database.
  screenshots.add(RefreshScreenshotsEvent());
}

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RulesBloc>()..add(LoadRulesEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _Body()),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// What SHOTO has already read, loaded once for the whole screen.
  ///
  /// Both the cards and the builder want the same answer — "what would this
  /// rule actually take?" — and it is two full-table reads. Loading it here
  /// and handing it down means the sheet opens with the answer already in
  /// hand instead of showing a blank preview for its first second.
  LibraryInsight _insight = LibraryInsight.empty;

  late final LibraryIndexer _indexer = sl<LibraryIndexer>();
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _indexer.addListener(_onIndexerChanged);
    // The shell has been running it since launch; this only matters on the
    // visit right after somebody subscribes, when the last sweep stopped at
    // the premium check.
    unawaited(_indexer.start());
    unawaited(_loadInsight());
  }

  @override
  void dispose() {
    _indexer.removeListener(_onIndexerChanged);
    _reloadTimer?.cancel();
    super.dispose();
  }

  /// Re-reads what the indexer has learned, at most once a second.
  ///
  /// Every card on this screen shows a count derived from the caches, so they
  /// climb on their own while the library is being read — which is the whole
  /// point: a rule that claims nothing because nothing has been read yet
  /// should visibly stop claiming nothing. Rebuilding on every notification
  /// would mean two full-table reads per screenshot indexed.
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

  /// The enabled rules that outrank position [index] — everything the builder
  /// needs to tell the user their rule matches plenty and would still get
  /// none of it.
  List<FilingRule> _above(List<FilingRule> rules, int index) => [
    for (int i = 0; i < index && i < rules.length; i++)
      if (rules[i].isEnabled) rules[i],
  ];

  Future<void> _addRule(BuildContext context, {RuleTemplate? template}) async {
    final List<FolderEntity> folders = await sl<GetFoldersUseCase>()();
    if (!context.mounted) return;

    // A rule files into a folder, so with none there is nothing to build.
    // Saying so beats an empty picker somebody stares at trying to work out
    // what they did wrong.
    if (folders.isEmpty) {
      showAppSnackBar(context, context.l10n.rulesNeedFolderFirst);
      return;
    }

    final RulesBloc bloc = context.read<RulesBloc>();
    final RulesState state = bloc.state;
    final List<FilingRule> rules = state is RulesLoadedState
        ? state.rules
        : const [];

    final RuleDraft? draft = await showRuleBuilderSheet(
      context,
      folders: folders,
      template: template,
      // A new rule lands at the bottom, so every enabled rule outranks it.
      higherPriority: _above(rules, rules.length),
    );
    if (draft == null) return;

    bloc.add(
      CreateRuleEvent(
        name: draft.name,
        folderId: draft.folderId,
        conditions: draft.conditions,
        match: draft.match,
      ),
    );
  }

  Future<void> _editRule(BuildContext context, FilingRule rule) async {
    final List<FolderEntity> folders = await sl<GetFoldersUseCase>()();
    if (!context.mounted) return;
    if (folders.isEmpty) {
      showAppSnackBar(context, context.l10n.rulesNeedFolderFirst);
      return;
    }

    final RulesBloc bloc = context.read<RulesBloc>();
    final RulesState state = bloc.state;
    final List<FilingRule> rules = state is RulesLoadedState
        ? state.rules
        : const [];

    final RuleDraft? draft = await showRuleBuilderSheet(
      context,
      folders: folders,
      existing: rule,
      higherPriority: _above(rules, rules.indexWhere((r) => r.id == rule.id)),
    );
    if (draft == null || draft.ruleId == null) return;

    bloc.add(
      UpdateRuleEvent(
        ruleId: draft.ruleId!,
        name: draft.name,
        folderId: draft.folderId,
        conditions: draft.conditions,
        match: draft.match,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.w, 8.h, 20.w, 6.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.rulesTitle,
                      style: AppTextStyles.headlineLarge,
                    ),
                    Text(
                      context.l10n.rulesSubtitle,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<RulesBloc, RulesState>(
            builder: (context, state) {
              if (state is RulesErrorState) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: context.l10n.commonSomethingWentWrong,
                  message: state.message.resolve(context),
                );
              }
              if (state is! RulesLoadedState) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final bool isEmpty = state.rules.isEmpty;

              return ListView(
                padding: EdgeInsetsDirectional.fromSTEB(20.w, 4.h, 20.w, 40.h),
                children: [
                  // Open on an empty screen, collapsed once there is
                  // something to look at instead.
                  RulesExplainer(startExpanded: isEmpty),
                  SizedBox(height: 16.h),

                  // Every number below it is out of what has been read, so
                  // the reading has to be visible. Without this a user
                  // watching their rule claim 3 of 500 screenshots has no way
                  // to tell a wrong rule from an unfinished sweep.
                  if (_indexer.isWorking) ...[
                    _IndexingNote(
                      remaining: _indexer.remaining,
                      fraction: _indexer.fraction,
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // Says the tie-break out loud, once, above the numbered
                  // list that demonstrates it. Two rules wanting the same
                  // screenshot is not an edge case — the templates alone
                  // produce it — and until the order was on screen the loser
                  // simply looked like a rule that did not work.
                  if (state.rules.length > 1) ...[
                    _PriorityNote(),
                    SizedBox(height: 12.h),
                  ],

                  for (int i = 0; i < state.rules.length; i++)
                    _RuleCard(
                      rule: state.rules[i],
                      rank: i + 1,
                      total: state.rules.length,
                      outcome: _insight.outcomeOf(
                        state.rules[i].conditions,
                        state.rules[i].match,
                        higherPriority: _above(state.rules, i),
                      ),
                      isIndexed: _insight.indexedCount > 0,
                      onEdit: () => _editRule(context, state.rules[i]),
                    ),

                  if (isEmpty) ...[
                    _TemplateList(
                      onPick: (template) =>
                          _addRule(context, template: template),
                    ),
                    SizedBox(height: 14.h),
                  ] else ...[
                    SizedBox(height: 6.h),
                    _RunCard(state: state),
                    SizedBox(height: 14.h),
                  ],

                  _AddButton(onTap: () => _addRule(context)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Says that SHOTO is still reading, and how much is left.
///
/// Shown on this screen rather than only in search because this is where it
/// changes what the numbers mean. A rule's claim count is taken from what has
/// been read; while that is still growing, every count on the screen is a
/// floor, and a floor presented without explanation reads as a verdict.
class _IndexingNote extends StatelessWidget {
  final int remaining;
  final double? fraction;

  const _IndexingNote({required this.remaining, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 15.w,
            height: 15.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Indeterminate until the sweep knows its own size — a
              // confident 0% is a worse lie than a spinner.
              value: fraction,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Text(
              context.l10n.indexingProgress(remaining),
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one-line statement of how ties are broken.
///
/// Shown only from the second rule onwards, because with one rule there is no
/// tie and the sentence is noise.
class _PriorityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(
            Icons.low_priority_rounded,
            size: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            context.l10n.rulesPriorityNote,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

/// One rule, with everything needed to judge it.
///
/// The card used to be a name, a sentence and a switch, which answers "what
/// does this say" but not the two questions people actually had: *does it
/// work*, and *why did the other rule get that screenshot*. So it now carries
/// its rank, what it currently claims, and — when it applies — the fact that
/// a rule above it takes the matches away.
class _RuleCard extends StatelessWidget {
  final FilingRule rule;

  /// Position in the priority order, from 1. Shown rather than implied by
  /// list position: the number is what the note above the list refers to.
  final int rank;
  final int total;

  /// What this rule takes out of the library as it stands.
  final RuleOutcome outcome;

  /// Whether SHOTO has read anything at all yet. Without this a fresh install
  /// shows every rule as claiming nothing, which reads as every rule being
  /// broken rather than as there being nothing to check them against.
  final bool isIndexed;

  final VoidCallback onEdit;

  const _RuleCard({
    required this.rule,
    required this.rank,
    required this.total,
    required this.outcome,
    required this.isIndexed,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.99,
      onTap: onEdit,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsetsDirectional.fromSTEB(14.w, 14.h, 10.w, 10.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: rule.isEnabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RankBadge(rank: rank, isEnabled: rule.isEnabled),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name, style: AppTextStyles.titleLarge),
                      SizedBox(height: 3.h),
                      // The rule in words. Without this the card would be a
                      // name and a switch, and "why did my screenshot move"
                      // would have no answer on screen — the thing that sank
                      // auto-albums.
                      Text(
                        context.l10n.rulesWhenIt(
                          RuleSummary.describe(context, rule),
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    AppSwitch(
                      value: rule.isEnabled,
                      onChanged: (value) => context.read<RulesBloc>().add(
                        SetRuleEnabledEvent(rule.id, value),
                      ),
                    ),
                    PressableScale(
                      scale: 0.85,
                      onTap: () async {
                        final bool confirmed = await showConfirmDialog(
                          context,
                          title: context.l10n.rulesDeleteTitle,
                          message: context.l10n.rulesDeleteMessage,
                          confirmLabel: context.l10n.commonDelete,
                          isDestructive: true,
                        );
                        if (confirmed && context.mounted) {
                          context.read<RulesBloc>().add(
                            DeleteRuleEvent(rule.id),
                          );
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18.sp,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(child: _Evidence(outcome: outcome, known: isIndexed)),
                if (total > 1)
                  _MoveButtons(
                    canMoveUp: rank > 1,
                    canMoveDown: rank < total,
                    onMove: (up) =>
                        context.read<RulesBloc>().add(
                          MoveRuleEvent(rule.id, up: up),
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The rule's place in the priority order.
class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isEnabled;

  const _RankBadge({required this.rank, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.caption.asMedium.copyWith(
          color: isEnabled ? AppColors.primary : AppColors.textDisabled,
        ),
      ),
    );
  }
}

/// What this rule is currently doing, in one line.
///
/// The number people were missing. A rule they cannot check is a rule they
/// stop trusting, and "claims 12" next to a folder name is the cheapest
/// possible proof that it is not just sitting there.
class _Evidence extends StatelessWidget {
  final RuleOutcome outcome;

  /// False until SHOTO has read at least one screenshot — see
  /// [_RuleCard.isIndexed].
  final bool known;

  const _Evidence({required this.outcome, required this.known});

  @override
  Widget build(BuildContext context) {
    if (!known) {
      return Text(
        context.l10n.rulesCardNotIndexed,
        style: AppTextStyles.caption,
      );
    }

    final int filed = outcome.filed.length;

    // Ordered by what the user needs to hear first. A rule that matches
    // things and files none of them is the state that reads as "broken", and
    // it has two completely different causes — another rule got there, or the
    // screenshots are already in a folder and a run never moves those. Saying
    // "claims 1" for either was the bug: the number was true and the rule
    // still did nothing, forever, with no way to find out why.
    final (String text, bool isProblem) = switch (outcome) {
      _ when outcome.taken.isNotEmpty => (
        context.l10n.rulesCardOverruled(outcome.taken.length),
        true,
      ),
      _ when outcome.alreadyFiled.isNotEmpty && filed == 0 => (
        context.l10n.rulesCardAlreadyFiled(outcome.alreadyFiled.length),
        true,
      ),
      _ when filed > 0 => (context.l10n.rulesCardClaims(filed), false),
      _ => (context.l10n.rulesCardClaimsNone, false),
    };

    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: isProblem ? AppColors.warning : AppColors.textSecondary,
      ),
    );
  }
}

/// Moves a rule one place up or down the priority order.
///
/// Arrows rather than a drag handle: this list scrolls, the cards are tall,
/// and a long-press drag inside a `ListView` fights the scroll on every other
/// attempt. Two taps that always work beat one gesture that sometimes does.
class _MoveButtons extends StatelessWidget {
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onMove;

  const _MoveButtons({
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Arrow(
          icon: Icons.keyboard_arrow_up_rounded,
          enabled: canMoveUp,
          semanticLabel: context.l10n.rulesMoveUp,
          onTap: () => onMove(true),
        ),
        _Arrow(
          icon: Icons.keyboard_arrow_down_rounded,
          enabled: canMoveDown,
          semanticLabel: context.l10n.rulesMoveDown,
          onTap: () => onMove(false),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  const _Arrow({
    required this.icon,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Kept in place when disabled rather than removed, so the two arrows do
    // not shuffle sideways as a rule reaches the top or the bottom of the
    // list — the control has to stay where the finger last found it.
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: PressableScale(
        scale: 0.85,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: Icon(
            icon,
            size: 21.sp,
            color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

/// Applies the rules to what is already sitting unsorted.
///
/// Separate from the automatic path on purpose: rules normally run the
/// instant a screenshot arrives, so this exists only for the backlog that
/// predates them — and it is a button rather than something that happens by
/// itself, because a pile of screenshots silently rearranging is alarming
/// even when every move is correct.
class _RunCard extends StatelessWidget {
  final RulesLoadedState state;
  const _RunCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final RuleRunResult? last = state.lastRun;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.rulesBacklogTitle, style: AppTextStyles.titleSmall),
          SizedBox(height: 3.h),
          Text(
            state.isRunning
                ? context.l10n.rulesBacklogRunning(
                    // isRunning is exactly "runProgress != null", so inside
                    // this branch both are set; the fallbacks only satisfy
                    // the compiler, which cannot see that link.
                    state.runProgress ?? 0,
                    state.runTotal ?? 0,
                  )
                : last == null
                ? context.l10n.rulesBacklogIdle
                : last.examined == 0
                ? context.l10n.rulesBacklogNothing
                : context.l10n.rulesBacklogResult(last.filed, last.examined),
            style: AppTextStyles.bodySmall,
          ),

          // The part the result line used to leave out. A pass only reads so
          // many never-before-seen screenshots, so on a library that has
          // never been indexed "filed 3 of 200" is not a verdict on the
          // rules — most of those 200 were matched against nothing. Saying so
          // turns "my rules don't work" into "tap it again".
          if (!state.isRunning && (last?.hasMoreToRead ?? false)) ...[
            SizedBox(height: 6.h),
            Text(
              context.l10n.rulesBacklogUnread(last!.unread),
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ],

          SizedBox(height: 12.h),
          PressableScale(
            scale: 0.97,
            onTap: state.isRunning
                ? null
                : () => context.read<RulesBloc>().add(RunRulesEvent()),
            child: Container(
              height: 44.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: state.isRunning
                    ? AppColors.surface
                    : AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: state.isRunning
                      ? AppColors.border
                      : AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: state.isRunning
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      context.l10n.rulesRunNow,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The examples, offered only while there are no rules.
///
/// They disappear once a rule exists, because their whole job is to get past
/// the blank page — after that they are four more things to scroll past on a
/// screen the user already understands.
class _TemplateList extends StatelessWidget {
  final ValueChanged<RuleTemplate> onPick;
  const _TemplateList({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(
            context.l10n.rulesStartTemplates.toUpperCase(),
            style: AppTextStyles.overline,
          ),
        ),
        for (final RuleTemplate template in RuleTemplate.all)
          if (RuleTemplate.isValid(template))
            PressableScale(
              scale: 0.98,
              onTap: () => onPick(template),
              child: Container(
                margin: EdgeInsets.only(bottom: 9.h),
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(17.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Icon(
                        template.icon,
                        size: 17.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 13.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title(context),
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 1.h),
                          // Says *why* the example matches what it matches.
                          // Without this the list is four nouns and the user
                          // still has not learned what a condition is.
                          Text(
                            template.rationale(context),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textDisabled,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
        SizedBox(height: 6.h),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(17.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              context.l10n.rulesNew,
              style: AppTextStyles.button.copyWith(color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
