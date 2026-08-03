import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_brand.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The SHOTO **brand** mark: a tray with three screenshots filed into it.
///
/// Not to be confused with `ShotoMark` in `shoto_mark.dart`, which is a
/// different object doing a different job — that one is the empty-state
/// illustration, drawn in the interface's own achromatic palette and holding
/// whatever icon the screen it appears on is about. This one is the logo: it
/// is blue, it is the same in both themes, and it never changes.
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
/// from the one on the splash.
///
/// It also buys the thing a bitmap fundamentally cannot: the three cards are
/// separate objects with their own transforms, so they can be animated in
/// individually. That is what the splash does, and it is why this is built as
/// three cards and a tray rather than as one shape that happens to look like
/// three cards and a tray.
///
/// ---
///
/// **Coordinate system.** Everything below is written in a 100×100 box with no
/// units. [ShotoBrandMarkPainter] scales that box to whatever size it is asked
/// for, so the numbers here are proportions and never need touching again.

// ---------------------------------------------------------------- the tray

/// Outer walls.
const double _trayLeft = 5;
const double _trayRight = 95;
const double _trayBottom = 100;

/// Where the front face's top edge sits at the left and right walls.
const double _trayRim = 43;

const double _trayRadiusTop = 6;
const double _trayRadiusBottom = 26;

/// The scoop in the middle of the front face.
///
/// This is the one feature of the shape that is not a rounded rectangle, and
/// it is doing two jobs: it is how a pocket is drawn — the front is cut down
/// so you can reach in — and it is what stops the mark from being a folder,
/// which is a shape every file app on the phone already owns.
///
/// 42 units across and 16 deep. An earlier cut was 42 *deep* over the same
/// width, which is a keyhole rather than a scoop: at that ratio the curve
/// turns back on itself, reads as a hole punched through the tray, and takes a
/// bite out of the middle of the picture on the front card.
const double _notchCentre = 50;
const double _notchHalfWidth = 21;
const double _notchBottom = 59;

/// How far the scoop's control points sit from each end.
///
/// Half its own half-width, so the curve leaves the rim horizontally and
/// arrives at the bottom horizontally, and the transition at both ends has no
/// corner in it at any size.
const double _notchEase = 11;

/// The inside back wall. Taller than the front face, so a band of it shows
/// above the rim — that band is the only thing telling the eye the tray is
/// open at the top rather than solid.
const double _backLeft = 7.5;
const double _backRight = 92.5;
const double _backTop = 38;
const double _backBottom = 95;

// --------------------------------------------------------------- the cards

const double _cardWidth = 74;
const double _cardHeight = 66;
const double _cardRadius = 5;

/// Where each card comes to rest, and how far it is turned there.
///
/// **A stack, not a fan**, and the difference is the whole character of the
/// mark. The fan this replaced spread the three cards across -8.5° to +1.5°
/// and offset them sideways, which reads as a hand of playing cards — held,
/// being chosen from, on their way somewhere. Filed screenshots are none of
/// those things. They are put away, squared up, and left.
///
/// So the three sit almost on top of each other, each stepped down and to the
/// right by about five units, all turned within a degree of the same slight
/// angle. What shows of the two behind is a sliver each, which is exactly
/// what shows of the paper under the top sheet in a real pile.
const List<Offset> _cardRest = [
  Offset(45.0, 37.0),
  Offset(50.0, 42.0),
  Offset(55.0, 48.0),
];

const List<double> _cardRestTurn = [-3.5, -3.0, -2.5];

/// Where each card starts before it is filed.
///
/// Above the frame entirely — at these offsets the lowest edge of the lowest
/// card is still off the top of the mark's box — and spread further apart than
/// they land, so the movement reads as a gathering rather than as a drop. They
/// also arrive turned further than they finish, which means the last thing
/// each card does before it settles is straighten, and straightening is what
/// reads as landing.
const List<Offset> _cardEntry = [
  Offset(-16, -86),
  Offset(-2, -94),
  Offset(14, -84),
];

const List<double> _cardEntryTurn = [-13, -5, 12];

/// Smaller while it is far away. Twelve points of scale is not perspective,
/// it is just enough for the eye to read distance instead of reading a card
/// sliding down a pane of glass.
const double _cardEntryScale = 0.88;

/// When each card's own movement starts, as a fraction of the whole.
///
/// Back card first. Filing them front to back would mean each new card lands
/// *behind* one already at rest, which is not how a stack is built and reads —
/// oddly specifically — as wrong.
const List<double> _cardDelay = [0.00, 0.15, 0.30];

/// How long one card's movement lasts, as a fraction of the whole. The last
/// card starts at 0.30 and this ends it exactly at 1.0.
const double _cardSpan = 0.70;

/// The card is invisible for the first instant of its span.
///
/// Only relevant on the splash, where the painter covers the whole screen and
/// a card would otherwise blink into existence in open space above the mark.
/// Fading over the first quarter of the travel hides the arrival without
/// turning the entrance into a fade, which is a different and much duller
/// animation.
const double _cardFadeSpan = 0.25;

/// How far a card's shadow falls on the one behind it, and how soft it is.
///
/// Down and very slightly left, matching the light in [AppBrand.backdrop].
/// Getting this backwards is the classic tell of a drawn icon: a shadow that
/// disagrees with the gradient behind it makes the whole object read as
/// pasted on.
const Offset _cardShadowOffset = Offset(-0.6, 2.2);
const double _cardShadowBlur = 2.6;

// ------------------------------------------------------------------ centring

/// The drawn content does not fill its box — it runs from y≈4, the top corner
/// of the mint card, to y=100 at the bottom of the tray, and from x≈8 to x≈93
/// — so it is nudged to sit in the middle. Without this the mark looks low and
/// left in every frame that contains it, which is the kind of thing nobody can
/// name but everybody sees.
const double _contentOffsetX = -1.5;
const double _contentOffsetY = -2.0;

/// How much of the backdrop slab the mark is allowed to occupy.
///
/// 0.75 of the box, and the box is now ~96% covered by drawn content — the
/// stack is far taller in its frame than the old fan was — so the mark covers
/// ~72% of the icon. That is not a taste number: it is the middle of the range
/// both platforms' icon grids are built around, and a glyph running wider than
/// about 78% looks cramped beside every other icon on the home screen once the
/// system rounds its corners off.
///
/// It moved from 0.86 with the switch from a fan to a stack. The content got
/// taller and narrower, so the same inset would have pushed the mark past the
/// grid; the number that stayed the same is the one that matters, which is how
/// much of the finished icon the drawing covers.
const double _markInset = 0.75;

/// The slab's corner radius as a fraction of its width — Apple's superellipse
/// ratio, near enough that the mark reads correctly inside whatever mask each
/// platform applies. It is what the splash and the in-app logo actually
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
/// full-screen splash with the cards flying in through the empty space around
/// it.
class ShotoBrandMarkPainter extends CustomPainter {
  /// The side length, in logical pixels, of the mark's 100×100 box.
  final double markExtent;

  /// 0 — the cards are outside the frame. 1 — all three are filed.
  ///
  /// The per-card stagger is applied inside this painter rather than by the
  /// caller, so the choreography is described in one place and a screen that
  /// wants it only has to drive a single number from 0 to 1.
  final double progress;

  /// Paint the blue slab behind the mark. Off gives the tray and cards alone
  /// on transparency.
  final bool backdrop;

  /// Paint the tray and cards. Off gives the bare slab.
  ///
  /// [backdrop] and [mark] are separate switches rather than one enum because
  /// Android's adaptive icons need exactly this: the same drawing split into
  /// two layers the launcher can move independently of each other, so the
  /// slab is one file and the mark is another and they are cut from the same
  /// geometry rather than from two guesses at it.
  final bool mark;

  /// Overrides the slab's corner radius, as a fraction of its width.
  ///
  /// Zero gives a full-bleed square, which is what both platforms want when
  /// they intend to apply their own mask — iOS rounds every icon itself, and
  /// an icon that arrives pre-rounded gets rounded twice and ends up with a
  /// pale halo where its corners used to be.
  final double? backdropCornerRadius;

  /// Off draws an empty tray.
  ///
  /// This exists for the native launch window, which has to show the mark
  /// *before* Flutter is running and therefore cannot show anything moving.
  /// It shows the tray empty, the first Flutter frame draws the same empty
  /// tray at the same size in the same place, and the cards then arrive into
  /// it — so the handover from the OS to the app has nothing to give it away.
  final bool cards;

  /// Flattens the mark to a single-colour stencil, for Android 13's themed
  /// icons — the launcher throws away every colour and tints whatever alpha is
  /// left with the user's wallpaper palette.
  ///
  /// This is not the same as painting the mark and then discarding its colour,
  /// which is what the first version did and why it needed replacing: four
  /// overlapping shapes, all reduced to the same value, fuse into one blob
  /// with a lumpy outline and nothing readable inside it. Every part of the
  /// drawing that says "this is a stack of pictures" is a *colour* boundary,
  /// and colour is exactly what a themed icon does not have.
  ///
  /// So in this mode each shape is cut out of the ones behind it along with a
  /// hairline of clearance around it — see [_monochromeGap]. The boundaries
  /// that were colour become gaps, and the silhouette keeps its structure.
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
      final RRect shape = RRect.fromRectAndRadius(
        slab,
        Radius.circular((backdropCornerRadius ?? _backdropRadius) * 100),
      );

      canvas.drawRRect(
        shape,
        Paint()..shader = AppBrand.backdrop.createShader(slab),
      );

      // The lit edge, stroked just inside the silhouette and clipped to it so
      // the outer half of the stroke never widens the shape. It fades out by
      // halfway down: a rim light that runs the whole way round stops being a
      // highlight and becomes a border, which is the difference between an
      // object and a sticker.
      canvas.save();
      canvas.clipRRect(shape);
      canvas.drawRRect(
        shape.deflate(0.7),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppBrand.backdropRim,
              Color(0x66FFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0.0, 0.18, 0.55],
          ).createShader(slab)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.restore();

      canvas.translate(
        (100 - _markInset * 100) / 2,
        (100 - _markInset * 100) / 2,
      );
      canvas.scale(_markInset);
    }

    if (mark) {
      // Deliberately *not* clipped to the slab. The cards begin outside it and
      // that is the point of the animation — they are things being put away,
      // not things emerging from inside the container they go into.
      canvas.translate(_contentOffsetX, _contentOffsetY);

      _paintTrayBack(canvas);
      if (cards) _paintCards(canvas);
      _paintTrayFront(canvas);
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
  /// works on any outline including the tray's scoop.
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

  // ------------------------------------------------------------------ tray

  void _paintTrayBack(Canvas canvas) {
    final RRect back = RRect.fromLTRBAndCorners(
      _backLeft,
      _backTop,
      _backRight,
      _backBottom,
      topLeft: const Radius.circular(9),
      topRight: const Radius.circular(9),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );

    _fill(canvas, Path()..addRRect(back), Paint()..color = AppBrand.trayBack);

    // The lit top edge of the back wall, clipped to the wall so only the inner
    // half of the stroke survives and the silhouette stays exact. There is no
    // lit edge without light, so a stencil does not get one.
    if (monochrome) return;

    canvas.save();
    canvas.clipRRect(back);
    canvas.drawRRect(
      back,
      Paint()
        ..color = AppBrand.trayRim.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.restore();
  }

  /// The front face, and the last thing painted — so the cards disappear
  /// behind it exactly as they would into a real pocket. Nothing about the
  /// cards has to know the tray exists.
  void _paintTrayFront(Canvas canvas) {
    final Path front = _trayFrontPath(closed: true);

    const Rect face = Rect.fromLTRB(
      _trayLeft,
      _trayRim,
      _trayRight,
      _trayBottom,
    );

    _fill(
      canvas,
      front,
      Paint()..shader = AppBrand.trayFront.createShader(face),
    );

    if (monochrome) return;

    // The sides falling away. Laid over the vertical gradient rather than
    // folded into it, because they are perpendicular — one shader cannot do
    // both, and a front face lit only from the top reads as a flat panel
    // leaning back instead of as something round.
    canvas.save();
    canvas.clipPath(front);
    canvas.drawRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            AppBrand.trayEdgeShade,
            Color(0x00001C6E),
            Color(0x00001C6E),
            AppBrand.trayEdgeShade,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ).createShader(face),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(front);
    canvas.drawPath(
      _trayFrontPath(closed: false),
      Paint()
        // Faded at both ends rather than drawn at a flat opacity.
        //
        // A constant stroke stops dead where the path does, and the clip
        // leaves two little rounded stubs sitting on the tray's shoulders that
        // read as a drawing mistake. Running it out to nothing over the last
        // eighth turns the same line into light falling off the curve, which
        // is what a lit edge does on a real object.
        ..shader =
            const LinearGradient(
              colors: [
                Color(0x00000000),
                AppBrand.trayRim,
                AppBrand.trayRim,
                Color(0x00000000),
              ],
              stops: [0.0, 0.12, 0.88, 1.0],
            ).createShader(
              const Rect.fromLTRB(_trayLeft, _trayRim, _trayRight, _trayBottom),
            )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  /// The front face.
  ///
  /// [closed] false stops after the top edge and returns it as an open path,
  /// which is what gets stroked for the lit rim. One function rather than two
  /// because the rim has to follow the fill exactly — the moment they are
  /// written out separately, a change to the scoop gets made in one of them.
  Path _trayFrontPath({required bool closed}) {
    final Path path = Path()
      ..moveTo(_trayLeft, _trayRim + _trayRadiusTop)
      ..quadraticBezierTo(
        _trayLeft,
        _trayRim,
        _trayLeft + _trayRadiusTop,
        _trayRim,
      )
      ..lineTo(_notchCentre - _notchHalfWidth, _trayRim)
      ..cubicTo(
        _notchCentre - _notchHalfWidth + _notchEase,
        _trayRim,
        _notchCentre - _notchEase,
        _notchBottom,
        _notchCentre,
        _notchBottom,
      )
      ..cubicTo(
        _notchCentre + _notchEase,
        _notchBottom,
        _notchCentre + _notchHalfWidth - _notchEase,
        _trayRim,
        _notchCentre + _notchHalfWidth,
        _trayRim,
      )
      ..lineTo(_trayRight - _trayRadiusTop, _trayRim)
      ..quadraticBezierTo(
        _trayRight,
        _trayRim,
        _trayRight,
        _trayRim + _trayRadiusTop,
      );

    if (!closed) return path;

    return path
      ..lineTo(_trayRight, _trayBottom - _trayRadiusBottom)
      ..quadraticBezierTo(
        _trayRight,
        _trayBottom,
        _trayRight - _trayRadiusBottom,
        _trayBottom,
      )
      ..lineTo(_trayLeft + _trayRadiusBottom, _trayBottom)
      ..quadraticBezierTo(
        _trayLeft,
        _trayBottom,
        _trayLeft,
        _trayBottom - _trayRadiusBottom,
      )
      ..close();
  }

  // ----------------------------------------------------------------- cards

  void _paintCards(Canvas canvas) {
    const List<Color> colours = [
      AppBrand.cardMint,
      AppBrand.cardCoral,
      AppBrand.cardPaper,
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
      final double scale = _lerp(_cardEntryScale, 1, t);
      final double opacity = (raw / _cardFadeSpan).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(turn * math.pi / 180);
      canvas.scale(scale);

      // One layer per card, so the fade applies to the card *and the picture
      // printed on it* as a single object. Fading them separately lets the
      // picture show through the card it is printed on.
      final bool layered = opacity < 1;
      if (layered) {
        canvas.saveLayer(
          const Rect.fromLTRB(-40, -40, 40, 40),
          Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
        );
      }

      final RRect shape = RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          -_cardWidth / 2,
          -_cardHeight / 2,
          _cardWidth,
          _cardHeight,
        ),
        const Radius.circular(_cardRadius),
      );

      // What this card throws onto the one behind it. Skipped for the back
      // card, which has nothing behind it but the tray's own back wall — a
      // shadow there lands on a surface far enough away that it would read as
      // grime rather than as depth.
      if (i > 0 && !monochrome) {
        canvas.drawRRect(
          shape.shift(_cardShadowOffset),
          Paint()
            ..color = AppBrand.cardShadow
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              _cardShadowBlur,
            ),
        );
      }

      _fill(canvas, Path()..addRRect(shape), Paint()..color = colours[i]);

      // The picture is skipped in a stencil. Cut out of the front card it
      // would read as a hole rather than as a photograph, and at the size a
      // themed icon is actually seen the sun and the hills are two specks.
      if (i == 2 && !monochrome) _paintPhoto(canvas);

      if (layered) canvas.restore();
      canvas.restore();
    }
  }

  /// The picture on the front card — the only place in the mark where SHOTO
  /// says what it holds. The two cards behind it are blank on purpose: three
  /// pictures at 48px is texture, one picture is a subject.
  void _paintPhoto(Canvas canvas) {
    const Rect frame = Rect.fromLTRB(-30, -25, 31, 28);
    final RRect photo = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(5),
    );

    canvas.drawRRect(photo, Paint()..color = AppBrand.photo);

    canvas.save();
    canvas.clipRRect(photo);

    canvas.drawCircle(
      const Offset(-2, -13),
      6.5,
      Paint()..color = AppBrand.photoSun,
    );

    // Both summits sit *above* the tray's rim, which is the whole reason the
    // picture is legible at all. Everything below the rim is behind the front
    // face, so hills drawn at a realistic height would be a landscape nobody
    // ever sees — only the scoop would show a sliver of them.
    final Path hills = Path()
      ..moveTo(-30, 28)
      ..lineTo(-10, -4)
      ..lineTo(0, 9)
      ..lineTo(12, -10)
      ..lineTo(31, 16)
      ..lineTo(31, 28)
      ..close();

    canvas.drawPath(hills, Paint()..color = AppBrand.photoDeep);
    // Stroked as well as filled, purely to round the summits. At the size an
    // app icon is actually looked at, a sharp point is the one thing that
    // reads as an artefact rather than as a drawing.
    canvas.drawPath(
      hills,
      Paint()
        ..color = AppBrand.photoDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
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
      old.centre != centre;
}

/// The brand mark at rest, sized to [size].
///
/// This is the one to reach for anywhere in the app. The splash drives
/// [ShotoBrandMarkPainter] directly, because it needs the cards to fly in
/// through space this widget does not own.
class ShotoBrandMark extends StatelessWidget {
  final double size;

  /// Off gives the tray and cards on transparency, for placing on a surface
  /// that is already coloured.
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
