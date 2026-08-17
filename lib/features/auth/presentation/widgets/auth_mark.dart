import 'package:flutter/material.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// The mark at the top of the sign-in screen, filing itself once as the screen
/// arrives.
///
/// This was a `ShotoLogo` — the same drawing, at rest, centred. Correct, and
/// mute: the first screen of the app showed a picture of the icon the user had
/// just tapped, which is the one thing they had already seen.
///
/// The mark is not a picture. Its three cards are separate objects with their
/// own transforms, and the whole reason `shoto_brand_mark.dart` is a painter
/// rather than a PNG is that they can be moved independently. Driving that here
/// means the first thing the app does, before it has asked for anything, is
/// **show what it is for**: two screenshots land, and the third lands filed,
/// with the corner cut off it. Nobody has to read a sentence to get that.
///
/// ---
///
/// **This is the second place the filing animation plays, and the second is the
/// limit.** `ProWelcomePage` runs it at 108px across the middle of the screen
/// when a subscription completes, and the argument written down there — that
/// choreography is a tax on anything you do daily and a gift on something that
/// happens once — applies here for the same reason and with the same rarity: an
/// account is created once per install.
///
/// What keeps them from being the same screen twice is scale and role. There
/// the mark is the subject, alone, at the centre, after money changed hands.
/// Here it is a masthead: [size] logical pixels, hard against the start edge,
/// with a column of type under it. Same gesture, said quietly — which is the
/// difference between a signature and a poster.
class AuthMark extends StatelessWidget {
  /// 0 — the cards are still outside the frame. 1 — all three are filed.
  ///
  /// Taken as an [Animation] rather than owned, because every other block on
  /// the sign-in screen is timed against this one and a screen with two clocks
  /// in it drifts. Must be driven **uncurved**: the painter eases each card on
  /// its own interval, and a curve applied to the parent bunches the three
  /// staggers together at whichever end of it is steepest.
  final Animation<double> progress;

  /// Flat logical pixels rather than `.w`, matching `ProWelcomePage`: the
  /// choreography inside the painter is described in proportions of this box,
  /// and scaling the box per device would quietly retime the travel.
  final double size;

  const AuthMark({super.key, required this.progress, this.size = 76});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // The cards begin above the mark's own box and are deliberately not
      // clipped to it — they are things being put away, not things emerging
      // from the container they go into. A boundary of its own keeps that
      // repaint off the rest of the column, which is not moving.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: progress,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            painter: ShotoBrandMarkPainter(
              markExtent: size,
              progress: progress.value,
            ),
            isComplex: true,
            willChange: true,
          ),
        ),
      ),
    );
  }
}
