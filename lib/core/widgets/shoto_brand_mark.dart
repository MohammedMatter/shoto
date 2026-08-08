import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_brand.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The Shoto **brand** mark: three screenshots, and the filed one in front.
///
/// It is the same object `ShotoMark` draws inside the app — a small fan of
/// cards with the clipped corner on the one Shoto is holding — in the brand's
/// fixed values rather than the interface's theme-aware ones. There used to be
/// two different marks here, a blue moulded tray for the launcher and this fan
/// for the empty states, and no user has ever been shown a reason for the
/// difference. See `app_brand.dart` for what the tray was and why it went.
///
/// ---
///
/// **Drawn, not shipped as an image**, and that is the design of this file
/// rather than an implementation detail.
///
/// A PNG would have needed five raster sizes for Android, sixteen for iOS, one
/// for the native launch window and one more for the app itself — twenty-three
/// files that must agree with each other forever, and a twenty-fourth problem
/// the moment the mark is wanted on a different background, because a PNG
/// carries whatever was behind it when it was exported. Every one of those
/// files is generated from the painter below (see
/// `tool/generate_brand_assets.dart`), so there is exactly one description of
/// what the mark looks like and the icon on the home screen cannot drift away
/// from the one on the launch window.
///
/// It also buys the thing a bitmap fundamentally cannot: the three cards are
/// separate objects with their own transforms, so they can be animated in
/// individually.
///
/// ---
///
/// **Coordinate system.** Everything below is written in a 100×100 box with no
/// units. [ShotoBrandMarkPainter] scales that box to whatever size it is asked
/// for, so the numbers here are proportions and never need touching again.

// --------------------------------------------------------------- the cards

const double _cardWidth = 46;
const double _cardHeight = 62;
const double _cardRadius = 4;

/// How large each card sits at rest.
///
/// The filed one is largest, and only slightly: this is depth, not emphasis,
/// and the cut corner is already doing the emphasis.
const List<double> _cardScale = [0.94, 0.97, 1.06];

/// The cut that makes a card a *filed* card.
///
/// The same gesture as [ClippedCorner] in `app_shapes.dart`, at the same
/// proportion — a straight chamfer off the top trailing corner, never a
/// rounded one, because the clip and the radius are the same idea and doing
/// both rounds the cut off into a nothing.
const double _frontCut = 14;

/// Where each card comes to rest, and how far it is turned there.
///
/// Two loose ones leaning back and to the left, and the filed one square in
/// front of them: the two behind are the screenshots you took, the one in
/// front is the one Shoto did something with.
///
/// **They lean one way rather than fanning both ways, and the cut corner is
/// the reason.** A symmetric fan puts a card directly behind the chamfer, and
/// a triangle of paper behind a cut corner does not read as a cut — it reads
/// as a folded page, which is the icon of every document app there has ever
/// been. Leaning the stack left clears the top trailing corner so the cut
/// opens onto the slab, where it says what it is.
const List<Offset> _cardRest = [
  Offset(36, 48),
  Offset(42, 45),
  Offset(53, 52),
];

const List<double> _cardRestTurn = [-10, -5, 0];

/// Where each card starts before it is filed.
///
/// Above the frame entirely — at these offsets the lowest edge of the lowest
/// card is still off the top of the mark's box — and turned further than they
/// finish, which means the last thing each card does before it settles is
/// straighten. Straightening is what reads as landing.
const List<Offset> _cardEntry = [
  Offset(-16, -86),
  Offset(-2, -90),
  Offset(12, -94),
];

const List<double> _cardEntryTurn = [-10, -8, 10];

/// Smaller while it is far away. Twelve points of scale is not perspective,
/// it is just enough for the eye to read distance instead of reading a card
/// sliding down a pane of glass.
const double _cardEntryScale = 0.88;

/// When each card's own movement starts, as a fraction of the whole.
///
/// The two loose cards first and the filed one last, because the filed card is
/// the point being made and the point lands at the end.
const List<double> _cardDelay = [0.00, 0.15, 0.30];

/// How long one card's movement lasts, as a fraction of the whole. The last
/// card starts at 0.30 and this ends it exactly at 1.0.
const double _cardSpan = 0.70;

/// The card is invisible for the first instant of its span.
///
/// Only relevant where the painter covers more than the mark's own box and a
/// card would otherwise blink into existence in open space above it. Fading
/// over the first quarter of the travel hides the arrival without turning the
/// entrance into a fade, which is a different and much duller animation.
const double _cardFadeSpan = 0.25;

/// How far the front card's shadow falls on the two behind it, and how soft.
const Offset _cardShadowOffset = Offset(0, 1.8);
const double _cardShadowBlur = 2.4;

// ---------------------------------------------------------------- centring

/// The stack leans left, so its drawn content does not sit in the middle of
/// the box it is described in. These two put it back. Without them the mark
/// sits low and left in every frame that contains it, which is the kind of
/// thing nobody can name but everybody sees.
const double _contentOffsetX = 6.5;
const double _contentOffsetY = 0.5;

/// How much of the backdrop slab the mark is allowed to occupy.
///
/// The fan is ~80% as wide as its own box, so this puts the drawing at ~72% of
/// the finished icon. That is not a taste number: it is the middle of the
/// range both platforms' icon grids are built around, and a glyph running
/// wider than about 78% looks cramped beside every other icon on the home
/// screen once the system rounds its corners off.
const double _markInset = 0.90;

/// The slab's corner radius as a fraction of its width — Apple's superellipse
/// ratio, near enough that the mark reads correctly inside whatever mask each
/// platform applies. It is what the launch window and the in-app logo actually
/// display, where nothing masks anything.
const double _backdropRadius = 0.2237;

/// The clearance cut around each shape in a monochrome stencil.
///
/// 1.6 units — about 1.6% of the mark — which at the ~64dp a themed icon is
/// drawn at comes to roughly a device pixel and a half. Any thinner and the
/// shapes fuse again on a low-density screen; any thicker and the cards start
/// to look like they are floating apart rather than stacked.
const double _monochromeGap = 1.6;

/// Paints the brand mark.
///
/// Sized by [markExtent] rather than by the canvas it is given, so the same
/// painter can fill a 48px icon or sit at 96 logical pixels in the middle of a
/// full screen with the cards flying in through the empty space around it.
class ShotoBrandMarkPainter extends CustomPainter {
  /// The side length, in logical pixels, of the mark's 100×100 box.
  final double markExtent;

  /// 0 — the cards are outside the frame. 1 — all three are filed.
  ///
  /// The per-card stagger is applied inside this painter rather than by the
  /// caller, so the choreography is described in one place and a screen that
  /// wants it only has to drive a single number from 0 to 1.
  final double progress;

  /// Paint the slab behind the mark. Off gives the cards alone on
  /// transparency.
  final bool backdrop;

  /// Paint the cards. Off gives the bare slab.
  ///
  /// [backdrop] and [mark] are separate switches rather than one enum because
  /// Android's adaptive icons need exactly this: the same drawing split into
  /// two layers the launcher can move independently of each other, so the
  /// slab is one file and the cards are another and they are cut from the
  /// same geometry rather than from two guesses at it.
  final bool mark;

  /// Overrides the slab's corner radius, as a fraction of its width.
  ///
  /// Zero gives a full-bleed square, which is what both platforms want when
  /// they intend to apply their own mask — iOS rounds every icon itself, and
  /// an icon that arrives pre-rounded gets rounded twice and ends up with a
  /// pale halo where its corners used to be.
  final double? backdropCornerRadius;

  /// Off draws the slab with nothing on it.
  ///
  /// Kept for anything that needs the mark's container without its contents;
  /// the launch window used to use it to show an empty tray, back when there
  /// was a tray to show.
  final bool cards;

  /// Flattens the mark to a single-colour stencil, for Android 13's themed
  /// icons — the launcher throws away every colour and tints whatever alpha is
  /// left with the user's wallpaper palette.
  ///
  /// This is not the same as painting the mark and then discarding its colour,
  /// which is what the first version did and why it needed replacing:
  /// overlapping shapes all reduced to the same value fuse into one blob with
  /// a lumpy outline and nothing readable inside it.
  ///
  /// So in this mode each shape is cut out of the ones behind it along with a
  /// hairline of clearance around it — see [_monochromeGap]. The boundaries
  /// that were value become gaps, and the silhouette keeps its structure.
  final bool monochrome;

  /// Where the centre of the mark sits. Defaults to the centre of the canvas.
  final Offset? centre;

  const ShotoBrandMarkPainter({
    required this.markExtent,
    this.progress = 1,
    this.backdrop = true,
    this.mark = true,
    this.backdropCornerRadius,
    this.cards = true,
    this.monochrome = false,
    this.centre,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = centre ?? size.center(Offset.zero);

    canvas.save();
    canvas.translate(origin.dx - markExtent / 2, origin.dy - markExtent / 2);
    canvas.scale(markExtent / 100);

    // Monochrome needs its own layer: the shapes below cut themselves out of
    // what is already drawn with `BlendMode.clear`, and without somewhere to
    // cut *into* that would punch holes in whatever the mark was painted on
    // top of.
    if (monochrome) {
      canvas.saveLayer(const Rect.fromLTRB(-60, -60, 160, 160), Paint());
    }

    if (backdrop) {
      const Rect slab = Rect.fromLTWH(0, 0, 100, 100);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          slab,
          Radius.circular((backdropCornerRadius ?? _backdropRadius) * 100),
        ),
        Paint()..color = AppBrand.ink,
      );

      canvas.translate(
        (100 - _markInset * 100) / 2,
        (100 - _markInset * 100) / 2,
      );
      canvas.scale(_markInset);
    }

    if (mark && cards) {
      // Deliberately *not* clipped to the slab. The cards begin outside it and
      // that is the point of the animation — they are things being put away,
      // not things emerging from inside the container they go into.
      canvas.translate(_contentOffsetX, _contentOffsetY);
      _paintCards(canvas);
    }

    if (monochrome) canvas.restore();
    canvas.restore();
  }

  /// Fills [path], and in [monochrome] cuts it and a hairline of clearance out
  /// of everything already drawn first.
  ///
  /// The clearance is a stroke along the same outline in `clear`: half of it
  /// lands inside the shape, which the fill immediately puts back, and half
  /// lands outside, which is the gap. One pass, no path arithmetic, and it
  /// works on any outline including the chamfered one.
  void _fill(Canvas canvas, Path path, Paint paint) {
    if (!monochrome) {
      canvas.drawPath(path, paint);
      return;
    }

    canvas.drawPath(path, Paint()..blendMode = BlendMode.clear);
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = _monochromeGap * 2,
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFF000000));
  }

  // ----------------------------------------------------------------- cards

  void _paintCards(Canvas canvas) {
    const List<Color> colours = [
      AppBrand.paperBack,
      AppBrand.paperMid,
      AppBrand.paper,
    ];

    for (int i = 0; i < 3; i++) {
      // Each card is eased on its own clock. Curving the parent instead would
      // bunch all three staggers together at whichever end of the curve is
      // steepest, and the gaps between them would stop being equal.
      final double raw = ((progress - _cardDelay[i]) / _cardSpan).clamp(
        0.0,
        1.0,
      );
      final double t = AppMotion.standard.transform(raw);

      final bool isFront = i == 2;

      final Offset position = Offset.lerp(
        _cardRest[i] + _cardEntry[i],
        _cardRest[i],
        t,
      )!;
      final double turn = _lerp(
        _cardRestTurn[i] + _cardEntryTurn[i],
        _cardRestTurn[i],
        t,
      );
      final double scale = _lerp(
        _cardScale[i] * _cardEntryScale,
        _cardScale[i],
        t,
      );
      final double opacity = (raw / _cardFadeSpan).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(turn * math.pi / 180);
      canvas.scale(scale);

      // One layer per card, so the fade applies to the card *and what is
      // printed on it* as a single object. Fading them separately lets the
      // rules show through the card they are printed on.
      final bool layered = opacity < 1;
      if (layered) {
        canvas.saveLayer(
          const Rect.fromLTRB(-40, -40, 40, 40),
          Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
        );
      }

      const Rect box = Rect.fromLTWH(
        -_cardWidth / 2,
        -_cardHeight / 2,
        _cardWidth,
        _cardHeight,
      );
      final Path shape = isFront ? _filedCardPath(box) : _looseCardPath(box);

      // Only the front card casts one, onto the two it overlaps. The other
      // two have nothing behind them but the slab, where a shadow lands on a
      // surface far enough away that it reads as grime rather than as depth.
      if (isFront && !monochrome) {
        canvas.drawPath(
          shape.shift(_cardShadowOffset),
          Paint()
            ..color = AppBrand.cardShadow
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              _cardShadowBlur,
            ),
        );
      }

      _fill(canvas, shape, Paint()..color = colours[i]);
      if (isFront) _paintRules(canvas);

      if (layered) canvas.restore();
      canvas.restore();
    }
  }

  Path _looseCardPath(Rect box) => Path()
    ..addRRect(RRect.fromRectAndRadius(box, const Radius.circular(_cardRadius)));

  /// The filed card: rounded everywhere except the top trailing corner, which
  /// is cut straight off. Written out rather than composed from an [RRect]
  /// because the chamfer is not a corner radius and every attempt to fake it
  /// with one produces a soft nub instead of a cut.
  Path _filedCardPath(Rect box) {
    const double r = _cardRadius;
    const double c = _frontCut;

    return Path()
      ..moveTo(box.left + r, box.top)
      ..lineTo(box.right - c, box.top)
      ..lineTo(box.right, box.top + c)
      ..lineTo(box.right, box.bottom - r)
      ..arcToPoint(
        Offset(box.right - r, box.bottom),
        radius: const Radius.circular(r),
      )
      ..lineTo(box.left + r, box.bottom)
      ..arcToPoint(
        Offset(box.left, box.bottom - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(box.left, box.top + r)
      ..arcToPoint(
        Offset(box.left + r, box.top),
        radius: const Radius.circular(r),
      )
      ..close();
  }

  /// Two short rules on the filed card — the only place in the mark where
  /// Shoto says what it is holding.
  ///
  /// A picture was tried here and it is the wrong claim: a photograph says
  /// *gallery*, which is the app Shoto deliberately is not. Two lines of
  /// something written say *screenshot*, and they are what makes searching
  /// inside a picture make sense as an idea before anybody has read a word
  /// about it. The two cards behind are blank on purpose — three sets of rules
  /// at 48px is texture, one is a subject.
  void _paintRules(Canvas canvas) {
    const double h = 3.4;
    // Centred on the card rather than sitting in its lower third, where two
    // short bars read as a caption under a picture that is not there.
    const List<Rect> rules = [
      Rect.fromLTWH(-12, -5, 24, h),
      Rect.fromLTWH(-12, 3, 15, h),
    ];

    for (final Rect rule in rules) {
      final Path path = Path()
        ..addRRect(RRect.fromRectAndRadius(rule, const Radius.circular(h / 2)));

      // In a stencil these are holes, not shapes. Running them through [_fill]
      // cuts them out and then paints them back in the stencil's one colour,
      // which leaves each bar outlined by its own clearance gap — a hairline
      // ring around a black bar, at a size where the whole rule is three
      // pixels tall.
      canvas.drawPath(
        path,
        monochrome
            ? (Paint()..blendMode = BlendMode.clear)
            : (Paint()..color = AppBrand.rule),
      );
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(ShotoBrandMarkPainter old) =>
      old.progress != progress ||
      old.markExtent != markExtent ||
      old.backdrop != backdrop ||
      old.mark != mark ||
      old.backdropCornerRadius != backdropCornerRadius ||
      old.cards != cards ||
      old.monochrome != monochrome ||
      old.centre != centre;
}

/// The brand mark at rest, sized to [size].
///
/// This is the one to reach for anywhere in the app. Anything that needs the
/// cards to fly in through space this widget does not own drives
/// [ShotoBrandMarkPainter] directly.
class ShotoBrandMark extends StatelessWidget {
  final double size;

  /// Off gives the cards on transparency, for placing on a surface that is
  /// already coloured.
  final bool backdrop;

  const ShotoBrandMark({super.key, this.size = 64, this.backdrop = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: ShotoBrandMarkPainter(markExtent: size, backdrop: backdrop),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}
