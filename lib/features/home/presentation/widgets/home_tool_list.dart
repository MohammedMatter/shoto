import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/features/duplicates/presentation/pages/duplicates_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';

/// What Home offers to *do*, with the one that matters said loudest.
///
/// **This was four identical rows, and four identical rows were an argument
/// the app does not actually make.** `HomePage` has said in a comment for a
/// long time that Safe Share is the signature feature and that nothing which
/// merely duplicates another tab should outrank it — and then drew it as the
/// second of four peers, each with the same icon plate, the same two lines and
/// the same chevron. A list where every entry has identical weight tells the
/// reader the entries are interchangeable. These are not: one of them is the
/// reason somebody installed this, and two of them are utilities.
///
/// So the ranking is said the only two ways that cost nothing and add nothing:
/// Safe Share is **first**, and everything else about the four rows is
/// identical. There is no accent glyph, no rule, no heavier type on the
/// primary one. Two earlier versions tried each of those and both were the
/// same mistake in different sizes — a property that varies on exactly one row
/// out of four is not a hierarchy, it is an exception, and it reads as one
/// designed object next to three leftovers. Order is a hierarchy. It needs no
/// help, and in this app colour is reserved for *state* — the active tab, a
/// folder's own filing mark — not for "this one matters more".
///
/// ---
///
/// **What went, what came back, and why.**
///
/// * **The icon plates went.** A 38dp rounded square behind every glyph is
///   four more rectangles on a page already built from cards, and they were
///   doing no work: the glyph is legible on the canvas, and the plate was only
///   ever there to give it an edge it did not need.
/// * **The dividers went.** A rule between every pair chops one list into four
///   separate things. Spacing groups them perfectly well, and it is what lets
///   the section read as one block rather than as a fenced-off table.
/// * **The chevrons came back**, and taking them out was the real error in the
///   version before this one. Stripping the plates, the rules *and* the
///   disclosure glyphs at once left four rows that were beautiful and did not
///   look like controls — the section read as a paragraph of headings, and
///   nothing on it said it could be pressed. A chevron is the one universally
///   understood mark for "this row goes somewhere", it costs a 20sp glyph in
///   the most ignorable colour on the palette, and an interface that hides the
///   fact that it is interactive has not been simplified, it has been broken.
/// * **The row now answers a press by tinting**, not by shrinking, matching
///   `HomeInbox` and every row in Settings — and matching what
///   [PressFeedback] says at length about why a full-width row that scales
///   makes the whole page look like it shuddered.
class HomeToolList extends StatelessWidget {
  final ValueChanged<LibraryIntent> onOpenLibraryForIntent;
  final bool hasLibrary;

  const HomeToolList({
    super.key,
    required this.onOpenLibraryForIntent,
    required this.hasLibrary,
  });

  VoidCallback _orImportFirst(BuildContext context, VoidCallback whenReady) {
    if (hasLibrary) return whenReady;
    return () =>
        importScreenshots(context, bloc: context.read<ScreenshotsBloc>());
  }

  @override
  Widget build(BuildContext context) {
    // **Safe Share is first, and that is the whole of its promotion.**
    //
    // It used to sit second, under Import, which put the app's signature
    // feature below an errand. Order is the cheapest hierarchy there is and
    // the only one that costs nothing to read.
    final List<_Tool> tools = <_Tool>[
      _Tool(
        icon: Icons.shield_outlined,
        title: context.l10n.homeToolSafeShare,
        subtitle: context.l10n.homeToolSafeShareSubtitle,
        trial: FeatureTrial.safeShare,
        onTap: _orImportFirst(
          context,
          () => onOpenLibraryForIntent(LibraryIntent.protect),
        ),
      ),
      if (hasLibrary)
        _Tool(
          icon: Icons.add_photo_alternate_outlined,
          title: context.l10n.importTitle,
          subtitle: context.l10n.homeToolImportSubtitle,
          onTap: () =>
              importScreenshots(context, bloc: context.read<ScreenshotsBloc>()),
        ),
      _Tool(
        icon: Icons.content_copy_outlined,
        title: context.l10n.homeToolDuplicates,
        subtitle: context.l10n.homeToolDuplicatesSubtitle,
        onTap: _orImportFirst(context, () async {
          if (!await ensurePremium(context)) return;
          if (!context.mounted) return;
          await Navigator.of(
            context,
          ).push(FadeSlidePageRoute(builder: (_) => const DuplicatesPage()));
        }),
      ),
      _Tool(
        icon: Icons.view_agenda_outlined,
        title: context.l10n.homeToolStitch,
        subtitle: context.l10n.homeToolStitchSubtitle,
        trial: FeatureTrial.stitch,
        onTap: _orImportFirst(
          context,
          () => onOpenLibraryForIntent(LibraryIntent.merge),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final _Tool tool in tools) _ToolRow(tool: tool),
      ],
    );
  }
}

class _Tool {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// The paid feature behind this row, when there is one you can try for
  /// free. Null for the free tools and for the paid ones with no allowance.
  final FeatureTrial? trial;

  const _Tool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trial,
  });
}

/// One tool. **There is only one of these, and that is the point.**
class _ToolRow extends StatelessWidget {
  final _Tool tool;

  const _ToolRow({required this.tool});

  @override
  Widget build(BuildContext context) {
    // **Only while it is actually available.** A row that goes on advertising
    // a free try after the try is gone is the app promising something it will
    // refuse — the tap would land straight on the paywall, which is a worse
    // first impression than never having offered.
    //
    // Subscribers never see it either: to them it is not an offer, it is a
    // reminder that other people pay less.
    final FeatureTrial? trial = tool.trial;
    final bool showTrial =
        trial != null &&
        !sl<ProStatus>().isPro &&
        sl<FeatureTrials>().hasTrial(trial);

    return PressableScale(
      // Tints rather than shrinks. A full-width row that scales makes the page
      // look like it flinched, and the press has to be *withdrawn* every time
      // the finger turns out to be starting a scroll — see [PressFeedback].
      feedback: PressFeedback.highlight,
      onTap: tool.onTap,
      child: Padding(
        // Generous, because the plates and the rules are gone and spacing is
        // now the only thing separating one tool from the next. It is also
        // what keeps the whole row over the 44dp a finger needs without
        // drawing a target around it.
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: <Widget>[
            // A fixed box rather than the glyph's own width, so four icons of
            // four different widths still hang off one optical line — the
            // thing the icon plates were accidentally doing before, and the
            // only job of theirs worth keeping.
            SizedBox(
              width: 24.w,
              child: Icon(
                tool.icon,
                size: 21.sp,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          tool.title,
                          style: context.text.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showTrial) ...<Widget>[
                        SizedBox(width: 8.w),
                        const _FreeTryTag(),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // **On every row.** These lines are not decoration: "your
                  // gallery is never read" is the app's central promise about
                  // how it works, and "Join a scrolling capture" is the only
                  // thing that explains what merging even is.
                  Text(
                    tool.subtitle,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // The mark that says this is a control at all. `textDisabled` on
            // purpose: it has to be *found* rather than read, and four of them
            // down the trailing edge at any more weight would be the loudest
            // column in the section.
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textDisabled,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Free try" beside a paid tool's name.
///
/// A tint of the accent rather than a filled pill: it sits inside a list of
/// four rows that are otherwise pure text, and a solid chip there would be the
/// heaviest object in the section — which is the wrong emphasis for a label
/// that disappears the first time it is used.
class _FreeTryTag extends StatelessWidget {
  const _FreeTryTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.colors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.trialFree,
        style: context.text.overline.asSemiBold.copyWith(
          color: context.colors.success,
        ),
      ),
    );
  }
}
