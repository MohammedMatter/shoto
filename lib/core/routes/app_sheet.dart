import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The one way this app raises a bottom sheet.
///
/// Eight call sites were reaching for `showModalBottomSheet` directly and
/// each inherited Material's own timings — 250ms in, 200ms out — while every
/// other travelling surface in Shoto runs on [AppMotion.sheet] /
/// [AppMotion.normal]. Fifty milliseconds is not something anyone can name,
/// but it is exactly the kind of drift that makes an app feel assembled from
/// parts rather than designed: the quick-save panel and the folder picker are
/// the same gesture at two different speeds.
///
/// A note on the curve, since [AppMotion.drawer] exists and is *not* used
/// here. Flutter hard-codes the modal sheet's curve to `Easing.legacyDecelerate`
/// — `cubic-bezier(0, 0, 0.2, 1)` — inside a private widget, and
/// `sheetAnimationStyle` only reaches the durations. That curve is a genuine
/// strong ease-out, front-loaded the way the standards ask for, so the
/// honest trade is to take Flutter's curve and own the timing rather than
/// reimplement `ModalBottomSheetRoute` (drag-to-dismiss, keyboard insets,
/// scroll-controlled sizing and all) for a difference nobody can see.
/// [AppMotion.drawer] stays where it belongs: on the sheets this app
/// animates itself, like quick save.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,

  /// Overrides the entrance timing for the few sheets whose size makes the
  /// shared one read as slow.
  ///
  /// **Duration is not the same as distance.** [AppMotion.sheet] is tuned for
  /// a panel that covers a third of the screen; the same 280ms spent carrying
  /// a near-full-screen sheet is 280ms in which the phone is also re-blurring
  /// most of what is behind it, and the entrance is the one animation nobody
  /// looks away from. Shortening it is the honest fix — every frame saved is a
  /// frame that no longer has to be perfect.
  ///
  /// Left null by every ordinary sheet, which is the point: this is an
  /// exception with a reason, not a knob.
  Duration? enterDuration,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    // The route paints nothing. Every sheet is drawn on a `SheetSurface`,
    // which is frosted — and a blur with an opaque Material behind it is a
    // blur of nothing, so the fill has to be the sheet's own or there is no
    // point having one.
    //
    // Applied by the content rather than wrapped around it here, because a
    // scroll-controlled sheet decides its own height by insetting itself from
    // the top of the screen: glass wrapped around that inset would frost the
    // gap above the sheet as well.
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    // Matches the dialog scrim, so the two never look like different apps
    // dimming the same screen. Material's default is black54 — dark enough
    // that the sheet reads as a modal takeover rather than a layer, and dark
    // enough to waste the frost, since a blur of an almost-black rectangle is
    // an almost-black rectangle.
    barrierColor: Colors.black.withValues(alpha: 0.3),
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.duration(context, enterDuration ?? AppMotion.sheet),
      // Out faster than in. The entrance is the app answering a tap; the
      // exit is the app getting out of the way of a decision already made.
      reverseDuration: AppMotion.duration(context, AppMotion.normal),
    ),
  );
}
