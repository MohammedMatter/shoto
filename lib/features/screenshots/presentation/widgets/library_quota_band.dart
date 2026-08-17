import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/library_quota.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

/// How full this library is, at the top of the screen the library is on.
///
/// ## Why the app needed this at all
///
/// The free tier's cap has been enforced since it was written, and until now
/// it was **only ever expressed as a refusal**: `ensureUnderScreenshotLimit`
/// counts at the moment of the action and, if the answer is no, puts up a
/// paywall. So the first time anybody learned the limit existed was the moment
/// it stopped them — mid-task, with no warning it had been approaching and no
/// screen to look it up on afterwards. A ceiling you cannot see is
/// indistinguishable from the app breaking.
///
/// ## Why it is here rather than in Settings
///
/// It was tried in Settings twice: first as a free-standing block under the
/// subscription card, which looked exactly like what it was — text with
/// nothing around it, floating between a card and a section heading — and then
/// as that card's own last band, which was tidy but still filed the number
/// under *billing*.
///
/// This is the better answer, and the reason is what the number is *for*.
/// "You have kept 10 of 100" is not a fact about a plan, it is a fact about
/// this library, and it is only ever actionable in one place: the screen with
/// the screenshots on it, where somebody is deciding what to keep and what to
/// let go. Directly under the title, it is read on the way past rather than
/// gone looking for.
///
/// ## Quiet on purpose
///
/// No card, no border, no fill. This sits at the top of the one screen built
/// for browsing, and a boxed panel above the grid would be a permanent
/// deduction from the thing the screen exists to show. It is two lines of
/// text and a hairline bar, and it disappears entirely for anyone who has no
/// ceiling to report — see [LibraryQuotaBand.build].
class LibraryQuotaBand extends StatelessWidget {
  const LibraryQuotaBand({super.key});

  @override
  Widget build(BuildContext context) {
    // **Re-counted whenever the library's own state changes underneath it.**
    //
    // The shell re-counts on arriving at this tab, and that is enough right
    // up until somebody files a screenshot *without leaving the tab* — which
    // is the ordinary way to do it: pick a picture, choose a folder, stay
    // exactly where you are. Nothing changed tabs, so nothing re-counted, and
    // the band went on reporting the number it had when the page opened. Filing
    // ten things moved it by zero.
    //
    // Listening to the library's own state is the right trigger because it is
    // the same event: `AssignFolder` and `SetFavorite` both emit a new loaded
    // state, and both are exactly what "managed" means. The count itself is
    // one `COUNT(*)` against a local table, which its own service documents as
    // cheap enough to call on every visit.
    return BlocListener<ScreenshotsBloc, ScreenshotsState>(
      // Only when the *managed* population moved. Scrolling, filtering and
      // selecting all emit new states too, and re-counting on those would put
      // a query behind every tap on this page for a number that cannot have
      // changed.
      listenWhen: (ScreenshotsState before, ScreenshotsState after) =>
          _managedCount(before) != _managedCount(after),
      listener: (BuildContext context, ScreenshotsState _) =>
          unawaited(sl<LibraryQuota>().refresh()),
      child: _band(context),
    );
  }

  /// How many of the loaded screenshots are filed or starred.
  ///
  /// A *change* detector, not the quota itself: this only ever sees the slice
  /// currently loaded, which is filtered. The real number comes from the
  /// database — this decides when to go and ask for it.
  static int _managedCount(ScreenshotsState state) => state
      is ScreenshotsLoadedState
      ? state.screenshots.where((ScreenshotEntity s) => !s.isUnsorted).length
      : -1;

  Widget _band(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<LibraryQuota>(),
      builder: (BuildContext context, _) {
        final LibraryQuota quota = sl<LibraryQuota>();
        final int? used = quota.used;
        final int? cap = quota.limit;

        // **Nothing at all for a subscriber.**
        //
        // The Settings card is where "Unlimited" belongs, because that card is
        // a statement about the plan and the word is the plan's whole point.
        // Here it would be a line that can never change, printed above
        // somebody's screenshots on every single visit — which is decoration
        // wearing a statistic's clothes. A measure with nothing to measure
        // should not be drawn.
        //
        // Nothing while the count is still in flight either: a meter that
        // renders 0 of 100 for a frame and then jumps says "you have kept
        // nothing", which is both wrong and the most alarming thing this could
        // say by accident.
        if (used == null || cap == null) return const SizedBox.shrink();

        final AppPalette colors = context.colors;
        final bool isFull = used >= cap;
        final double fraction = cap <= 0 ? 0 : (used / cap).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(20.w, 2.h, 20.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    // No "Library" label here, unlike the version that lived
                    // in Settings. The page is already titled Library, two
                    // lines above; repeating it would be the same word twice
                    // inside a hundred pixels.
                    context.l10n.quotaUsed(used, cap),
                    // Tabular figures: this number moves while the app is
                    // open, and proportional digits make it jitter as it
                    // counts up.
                    style: context.text.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    // Never negative: a library already past the line when the
                    // cap arrived is a real state — the gate only ever refuses
                    // *new* items, so anyone over the line before the limit
                    // existed, or who filled up on Pro and then lapsed, keeps
                    // everything they had. "-37 screenshots left" is not a
                    // sentence. Clamped to zero, where the plural rule has a
                    // dedicated message saying the room is gone.
                    context.l10n.quotaLeft((cap - used).clamp(0, cap)),
                    style: context.text.caption.copyWith(
                      color: isFull ? colors.warning : colors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7.h),
              _QuotaBar(fraction: fraction, isFull: isFull),
            ],
          ),
        );
      },
    );
  }
}

/// The bar: one track, one fill, and a colour that changes exactly once.
///
/// **Amber only when the allowance is actually gone**, never as a gradient of
/// worry along the way. A bar that starts yellowing at 70% is telling somebody
/// they are running out while they still have thirty screenshots left, which
/// is a sales tactic wearing a progress bar's clothes. Until the line is
/// reached this is the ordinary accent, because until the line is reached
/// nothing is wrong.
class _QuotaBar extends StatelessWidget {
  final double fraction;
  final bool isFull;

  const _QuotaBar({required this.fraction, required this.isFull});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color fill = isFull ? colors.warning : colors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        children: <Widget>[
          Container(height: 4.h, color: colors.surfaceVariant),
          // Animated, because this is one of the few numbers in the app that
          // moves while the screen is open — file a batch of screenshots and
          // the bar growing to its new length is the whole reason it is a bar
          // rather than a fraction. Reduced motion collapses it to a jump
          // rather than removing the change.
          AnimatedFractionallySizedBox(
            duration: AppMotion.reduced(context)
                ? Duration.zero
                : AppMotion.sheet,
            curve: AppMotion.standard,
            widthFactor: fraction.clamp(0.0, 1.0),
            alignment: AlignmentDirectional.centerStart,
            child: Container(height: 4.h, color: fill),
          ),
        ],
      ),
    );
  }
}
