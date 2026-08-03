import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

/// The one way this app puts a dialog on screen.
///
/// `showDialog` was being called directly in three places, which meant three
/// copies of Flutter's default transition: a **fade and nothing else**, over
/// 150ms, with the backdrop blur snapping to full strength on the first
/// frame. A panel that fades in without changing size has no physicality —
/// it reads as a texture appearing over the screen rather than as a thing
/// arriving — and the instant blur is the giveaway, because the background
/// goes soft before the dialog is even legible.
///
/// So: scale from 0.96 rather than from nothing, blur ramping in step with
/// the panel, and an exit that is faster than the entrance because by then
/// the user has already decided and is waiting on the app.
///
/// Centred on purpose. Popovers should grow from whatever was tapped, but a
/// dialog is not anchored to anything — it owns the screen, and scaling it
/// from a corner would invent a relationship that isn't there.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,

  /// How far the backdrop behind the dialog is blurred at rest.
  ///
  /// Zero for dialogs that frost their own panel — stacking a full-screen
  /// blur under one of those means blurring already-blurred pixels, which
  /// costs two passes to look muddier than either alone.
  double blurSigma = AppBlur.dialog,
}) {
  // Built once for the whole route rather than inside the transition builder,
  // which runs every frame — a CurvedAnimation per frame is an allocation per
  // frame and a disposal Flutter will complain about in debug.
  CurvedAnimation? curve;

  final Future<T?> result = Navigator.of(context, rootNavigator: true).push<T>(
    _AppDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.3),
      transitionDuration: AppMotion.duration(context, AppMotion.normal),
      exitDuration: AppMotion.duration(context, AppMotion.press),
      pageBuilder: (context, _, _) => builder(context),
      transitionBuilder: (context, animation, _, child) {
        curve ??= CurvedAnimation(
          parent: animation,
          curve: AppMotion.standard,
          reverseCurve: AppMotion.standardReverse,
        );
        final CurvedAnimation curved = curve!;

        // Reduced motion keeps the fade — losing it entirely would make the
        // dialog teleport, which is a harsher change than the one being
        // avoided. Only the movement goes.
        if (AppMotion.reduced(context)) {
          return FadeTransition(opacity: curved, child: child);
        }

        final Widget panel = ScaleTransition(
          // 0.96, never 0. Nothing in the real world appears from nothing.
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        );

        return FadeTransition(
          opacity: curved,
          child: blurSigma == 0
              ? panel
              : AnimatedBuilder(
                  animation: curved,
                  builder: (context, blurred) => BackdropFilter(
                    // Well under the ~20px ceiling: heavy blur is the most
                    // expensive thing on this screen, and there is nothing
                    // behind it worth hiding that 12 doesn't hide.
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma * curved.value,
                      sigmaY: blurSigma * curved.value,
                    ),
                    child: blurred,
                  ),
                  child: panel,
                ),
        );
      },
    ),
  );

  result.whenComplete(() => curve?.dispose());
  return result;
}

/// [RawDialogRoute] with an exit that is allowed to be shorter than the
/// entrance.
///
/// `showGeneralDialog` has no `reverseTransitionDuration` parameter and
/// [TransitionRoute] defaults the reverse to the forward duration, so the
/// only way to make dismissing quicker than opening is to override the
/// getter. Worth the subclass: the entrance is the app answering a tap and
/// can afford to be seen, while the exit is the app clearing out of the way
/// of a decision the user has already made and is now waiting on.
class _AppDialogRoute<T> extends RawDialogRoute<T> {
  final Duration exitDuration;

  _AppDialogRoute({
    required super.pageBuilder,
    required super.transitionBuilder,
    required this.exitDuration,
    super.barrierDismissible,
    super.barrierLabel,
    super.barrierColor,
    super.transitionDuration,
  });

  @override
  Duration get reverseTransitionDuration => exitDuration;
}
