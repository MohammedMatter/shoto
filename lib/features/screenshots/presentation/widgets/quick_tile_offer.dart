import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/quick_tile.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

/// Offers the Quick Settings shortcut, once, to somebody who has already
/// filed something the slow way.
///
/// **Declaring a tile in the manifest does not put it in anyone's panel.** It
/// only lists it in the editor drawer, behind a pencil most people have never
/// pressed — Android reserves the panel itself for the user, which is right,
/// and which means a tile with no invitation is a feature nobody has. The
/// Settings row is the permanent way in; this is the one that finds people who
/// were never going to open Settings.
///
/// **Shown here, and the placement is the argument.** It cannot go in the
/// quick-save sheet: that sheet auto-closes about two seconds after a save, so
/// an offer inside it is one nobody could reach — and firing a system dialog
/// over a surface that is already sliding away is worse than not asking. Home
/// was rejected too; its block order is a decided thing (state → action →
/// content) and a promotion does not belong in any of the three. The Library
/// is the screen somebody opens *to deal with screenshots*, which is the only
/// context in which "here is a faster way to add them" is an answer rather
/// than an advertisement.
///
/// **Asked once, whatever the answer.** Android caps how often an app may
/// request a tile placement and stops honouring it after a few refusals, so a
/// second ask does not merely nag — it spends one of a handful of chances on
/// somebody who already declined. Dismissing counts as an answer for the same
/// reason.
///
/// Draws nothing at all on iOS, before anything has been filed, or once the
/// question has been put — so on the overwhelming majority of builds of this
/// screen it costs the layout exactly zero.
class QuickTileOffer extends StatefulWidget {
  const QuickTileOffer({super.key});

  @override
  State<QuickTileOffer> createState() => _QuickTileOfferState();
}

class _QuickTileOfferState extends State<QuickTileOffer> {
  /// Set the moment the row is acted on, before the platform answers.
  ///
  /// The preference is written too, but that is a `SharedPreferences` round
  /// trip and the system dialog arrives first — without this the row would
  /// still be sitting there behind it, and would flicker away a moment later
  /// for no reason the user can see.
  bool _answered = false;

  Future<void> _accept() async {
    setState(() => _answered = true);
    // Recorded before the outcome is known: the question has been put either
    // way, and that is what this flag is about.
    await sl<AppPreferences>().markTileOffered();

    final QuickTileOutcome outcome = await QuickTile.requestAdd();
    if (!mounted) return;
    switch (outcome) {
      case QuickTileOutcome.added:
        showAppSnackBar(context, context.l10n.settingsQuickTileAdded);
      // Silence. They have just told the system no; Shoto repeating itself a
      // moment later in its own voice is the app arguing with the answer.
      case QuickTileOutcome.declined:
        break;
      case QuickTileOutcome.unsupported:
        showAppSnackBar(context, context.l10n.settingsQuickTileManual);
    }
  }

  void _dismiss() {
    setState(() => _answered = true);
    sl<AppPreferences>().markTileOffered();
  }

  @override
  Widget build(BuildContext context) {
    if (_answered || !QuickTile.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: sl<AppPreferences>(),
      builder: (BuildContext context, Widget? child) {
        if (sl<AppPreferences>().tileOffered) return const SizedBox.shrink();

        return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
          // **Not before anything has been filed.** The offer is "there is a
          // faster way to do the thing you just did", and to somebody staring
          // at an empty library it is a shortcut to a task they have never
          // performed — which is how a good idea reads as clutter.
          buildWhen: (ScreenshotsState previous, ScreenshotsState current) =>
              _hasLibrary(previous) != _hasLibrary(current),
          builder: (BuildContext context, ScreenshotsState state) {
            if (!_hasLibrary(state)) return const SizedBox.shrink();
            return _card(context);
          },
        );
      },
    );
  }

  static bool _hasLibrary(ScreenshotsState state) =>
      state is ScreenshotsLoadedState && state.screenshots.isNotEmpty;

  Widget _card(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 4.h, 20.w, 12.h),
      child: PressableScale(
        onTap: _accept,
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 8.w, 12.h),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.bolt_outlined,
                size: 20.sp,
                color: context.colors.primary,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.quickTileOfferTitle,
                      style: context.text.titleSmall.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.l10n.quickTileOfferBody,
                      style: context.text.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // A real way out, not just somewhere else to tap. A one-time
              // card with no dismiss is one the user has to accept to be rid
              // of, which turns an offer into a toll.
              PressableScale(
                scale: 0.9,
                onTap: _dismiss,
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
