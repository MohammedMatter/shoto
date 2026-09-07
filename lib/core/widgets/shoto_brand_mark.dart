import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_brand.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The Shoto **brand** mark: three screenshots, and a bookmark on the kept one.
///
/// `ShotoMark` still draws the older shape inside the app — the same fan, with
/// a clipped corner where this one has a ribbon — and the two are **knowingly
/// out of step until somebody decides they should not be**. That is a smaller
/// problem than it looks: this is the launcher, the store listing and the
/// launch window; that is a decoration on empty states. See `app_brand.dart`
/// for what the mark was before this and why it changed.
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

/// One card before its own scale. Everything else is a proportion of these.
///
/// **4:5, where it was 46:62.** A screenshot is a phone screen and a phone
/// screen is taller than it is wide — but the stack is read inside a *square*,
/// and past about 4:5 it stops filling its box and starts reading as three
/// bookmarks rather than three pictures.
const double _cardWidth = 48;
const double _cardHeight = 60;

/// **9.6, where it was 4.** The old radius belonged to a card carrying a
/// chamfer: a straight cut beside a tight corner reads as a cut, and beside a
/// soft one reads as a nick, so the two had to be drawn against each other.
/// With no chamfer left the corner is free to be the radius the rest of the
/// app puts on a card.
const double _cardRadius = 9.6;

/// How large each card sits at rest.
///
/// The front one is a clear step larger rather than a slight one. It used to
/// be within six points of the others because the cut corner was carrying the
/// emphasis; the ribbon carries it now, and the ribbon needs a card big enough
/// to sit on at 40px.
const List<double> _cardScale = [0.926, 0.972, 1.157];

/// Where each card comes to rest, and how far it is turned there.
///
/// Two loose ones leaning back and to the left, and the kept one square in
/// front of them: the two behind are the screenshots you took, the one in
/// front is the one you asked for again.
///
/// **They still lean one way rather than fanning both ways**, though no longer
/// for the old reason — there is no chamfer to clear. A symmetric fan puts the
/// stack's mass under the ribbon and pushes the whole mark's weight to the
/// middle; leaning left opens the ground on that side and leaves the ribbon
/// the only thing standing on the right.
///
/// The centring is baked into these three rather than corrected afterwards by
/// a pair of offsets, which is what the old geometry did.
const List<Offset> _cardRest = [
  Offset(32.22, 55.56),
  Offset(41.11, 52.78),
  Offset(53.33, 51.11),
];

const List<double> _cardRestTurn = [-15, -7.5, 0];

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

// -------------------------------------------------------------- the ribbon

/// The bookmark, in the front card's own coordinates.
///
/// **This is the mark.** Everything above is a stack of pictures, which is a
/// shape a dozen apps already own; the ribbon is what makes it *this* app's
/// stack, and it is the only part of the drawing that survives being described
/// out loud — "the one with the bookmark".
///
/// It starts flush with the card's top edge rather than below it, because a
/// ribbon that begins inside the card is *printed on* it and one that runs off
/// the edge is *attached to* it. The first is a graphic; the second is an
/// object you could pull.
const double _ribbonLeft = 2.9;
const double _ribbonRight = 18.3;
const double _ribbonBottom = 10.6;

/// The V taken out of the bottom. Deep enough to still be a V at 20px, where
/// a shallow notch closes up into a flat bar and the ribbon turns into a
/// coloured stripe.
const double _ribbonNotch = 7.2;

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

  /// The slab's colour. [AppBrand.ground] unless a caller says otherwise.
  ///
  /// **The only parameter here that changes what the mark *is*, and it exists
  /// for exactly one caller.** `app_brand.dart` states that the mark's values
  /// are fixed rather than mode-aware, on the grounds that "a brand mark that
  /// changes with the system theme is not one mark, it is two, and neither of
  /// them is the one on the store listing". That argument is about the mark
  /// the app draws for itself, and it still holds — nothing in `lib/` passes
  /// this.
  ///
  /// What passes it is `tool/generate_brand_assets.dart`, building the
  /// alternate launcher icons. Those are a different case on the same
  /// reasoning: an alternate icon is not the app changing its mind about its
  /// mark, it is a set of *fixed* marks the user picks one of, and the one on
  /// the store listing is still the default. The geometry — the tray, the
  /// cards, the clipped corner — never changes, which is what keeps six icons
  /// recognisably one product rather than six logos.
  ///
  /// **The slab moves and the two cards behind move with it**, because they
  /// are solved from it — see [AppBrand.cardTones]. Only the front card and
  /// the ribbon are fixed, and those two are what a person recognises: the
  /// light shape and the red mark on it are identical on all six icons, so the
  /// set reads as one product wearing six colours rather than as six logos.
  final Color slab;

  const ShotoBrandMarkPainter({
    required this.markExtent,
    this.progress = 1,
    this.backdrop = true,
    this.mark = true,
    this.backdropCornerRadius,
    this.cards = true,
    this.monochrome = false,
    this.centre,
    this.slab = AppBrand.ground,
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
      // Named `bounds` rather than `slab`, which is what it was called until
      // the slab's *colour* became a parameter of the same name — a local Rect
      // shadowing a Color field is the kind of collision the analyser catches
      // only because the two types differ.
      const Rect bounds = Rect.fromLTWH(0, 0, 100, 100);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bounds,
          Radius.circular((backdropCornerRadius ?? _backdropRadius) * 100),
        ),
        Paint()..color = slab,
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
    // Derived from whatever slab this is being drawn on, so the five paid
    // variants get their own ramp rather than three teals on a plum ground.
    final (Color back, Color mid) = AppBrand.cardTones(slab);
    final List<Color> colours = <Color>[back, mid, AppBrand.paper];

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

      // **The stencil is the front card alone**, and that is a considered
      // simplification rather than a shortcut. In colour the two behind read
      // because they are steps of a hue; in monochrome the hue is gone and all
      // that is left of them is the sliver each one shows past the front card
      // — three or four units wide, minus a clearance gap on both sides. At
      // the 48px a themed icon is drawn at those become sub-pixel ribs, and
      // they do not read as cards, they read as scratches on the icon.
      //
      // What survives is the part anybody could name: a card with a bookmark
      // cut out of it. Dropping the stack costs the stencil a detail; keeping
      // it cost the stencil its silhouette.
      if (monochrome && !isFront) continue;

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
      final Path shape = _cardPath(box);

      // **Nothing casts a shadow any more.** The front card used to blur one
      // onto the two behind it, and it had to: three cards cut from the same
      // paper have no other way to say which is in front. They are three steps
      // of one hue now — see [AppBrand.cardTones] — so the depth is in the
      // fill, and a blur on top of it would be the same fact stated twice.
      // It also cost the mark the one thing it now claims to be, which is
      // flat.
      _fill(canvas, shape, Paint()..color = colours[i]);

      if (isFront) {
        // Clipped to the card it sits on, so the ribbon follows the rounded
        // top corner rather than hanging over it. It is fixed *to* the card
        // rather than floating in front of it, and at small sizes that is the
        // difference between an object and a smudge.
        canvas.save();
        canvas.clipPath(shape);
        _paintRibbon(canvas);
        canvas.restore();
      }

      if (layered) canvas.restore();
      canvas.restore();
    }
  }

  /// **All three cards are the same shape now**, which is why there is one of
  /// these where there used to be two.
  ///
  /// The front one carried a chamfer off its top trailing corner — the app's
  /// own gesture for *filed*, and the mark's only idea. It went because at
  /// launcher sizes it was not read as a cut: a triangle of dark ground behind
  /// a light card reads as a **folded page**, which is the icon of every
  /// document app there has ever been, and that is the exact misreading this
  /// file's own notes warned about while shipping it anyway. The ribbon makes
  /// the same claim, louder, and cannot be mistaken for a fold.
  Path _cardPath(Rect box) => Path()
    ..addRRect(RRect.fromRectAndRadius(box, const Radius.circular(_cardRadius)));

  /// The bookmark on the front card.
  ///
  /// **This replaced two short rules, and that swap is the whole redesign.**
  /// The rules were there to say *a screenshot with something written in it*.
  /// What they actually said was *a document*: three cards and two lines of
  /// text is Docs, is Notes, is Files, is Keep — and the app's entire thesis
  /// is that screenshots are pictures. The ribbon claims something the product
  /// can actually do instead, and it is a claim no file manager makes.
  ///
  /// Painted in [AppBrand.ribbon] on every variant, alone among everything
  /// here in not being derived from the slab.
  void _paintRibbon(Canvas canvas) {
    const double top = -_cardHeight / 2;
    const double middle = (_ribbonLeft + _ribbonRight) / 2;

    final Path path = Path()
      ..moveTo(_ribbonLeft, top)
      ..lineTo(_ribbonRight, top)
      ..lineTo(_ribbonRight, _ribbonBottom)
      ..lineTo(middle, _ribbonBottom - _ribbonNotch)
      ..lineTo(_ribbonLeft, _ribbonBottom)
      ..close();

    // In a stencil this is a hole rather than a shape. Android's themed icons
    // discard every colour, so a ribbon painted in the one value that survives
    // would disappear into the card it is printed on. Cut out, it is the only
    // piece of structure the themed icon keeps — and the reason the mark is
    // still recognisable there.
    canvas.drawPath(
      path,
      monochrome
          ? (Paint()..blendMode = BlendMode.clear)
          : (Paint()..color = AppBrand.ribbon),
    );
  }

  /// The tightest box the mark actually fills at rest, in the 100×100 box —
  /// **with no slab under it**, which is the only case that needs this.
  ///
  /// On a slab there is nothing to solve: the slab *is* the box, the drawing
  /// sits inside it wherever [_cardRest] puts it, and the deliberate weight to
  /// the left is read as composition because there is a frame to be composed
  /// in. Take the slab away and the same offset stops being composition and
  /// becomes a centring bug — the mark alone on a field is centred by its own
  /// ink or it is not centred at all. This is `(43.33, 51.27)` against the
  /// box's `(50, 50)`, which at the ~192dp a splash icon is drawn at is about
  /// thirteen physical pixels of drift. Easily enough to see, and impossible
  /// to attribute to anything once it ships.
  ///
  /// **Computed rather than typed**, from the same constants the painting
  /// reads, because the alternative is four magic numbers that go quietly
  /// wrong the next time a card moves. The support function of a rounded
  /// rectangle under rotation is exact — every extreme point lies on a corner
  /// arc, so the box is the arc centres' own extent plus one radius — which
  /// makes this the true bound rather than a safe over-estimate.
  ///
  /// Only the cards are measured. The ribbon is clipped to the front card, so
  /// it can never reach past one.
  static Rect get restBounds {
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;

    for (int i = 0; i < 3; i++) {
      final double s = _cardScale[i];
      final double halfWidth = _cardWidth / 2 * s;
      final double halfHeight = _cardHeight / 2 * s;
      final double radius = _cardRadius * s;

      final double turn = (_cardRestTurn[i] * math.pi / 180).abs();
      final double cos = math.cos(turn).abs();
      final double sin = math.sin(turn).abs();

      final double extentX =
          (halfWidth - radius) * cos + (halfHeight - radius) * sin + radius;
      final double extentY =
          (halfWidth - radius) * sin + (halfHeight - radius) * cos + radius;

      final Offset centre = _cardRest[i];
      left = math.min(left, centre.dx - extentX);
      right = math.max(right, centre.dx + extentX);
      top = math.min(top, centre.dy - extentY);
      bottom = math.max(bottom, centre.dy + extentY);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// The [markExtent] that makes a bare mark's ink exactly [width] across.
  ///
  /// The ink is wider than it is tall — 75.5 by 69.7 — so width is what binds
  /// inside any square container, and it is the only dimension anything asks
  /// for.
  static double extentForInkWidth(double width) =>
      width * 100 / restBounds.width;

  /// The [centre] to pass so a bare mark's *ink* lands centred on [inkCentre].
  ///
  /// [centre] positions the 100×100 box, and the ink is not centred inside it
  /// — see [restBounds]. This is the correction, and it is a static rather
  /// than a flag on the painter because it is arithmetic every caller would
  /// otherwise repeat slightly differently.
  static Offset centreForInk(Offset inkCentre, double markExtent) =>
      inkCentre -
      (restBounds.center - const Offset(50, 50)) * (markExtent / 100);

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
      old.centre != centre ||
      old.slab != slab;
}

/// The brand mark at rest, sized to [size].
///
/// This is the one to reach for anywhere in the app. Anything that needs the
/// cards to fly in through space this widget does not own drives
/// [ShotoBrandMarkPainter] directly.
class ShotoBrandMark extends StatelessWidget {
  /// The slab's corner radius as a fraction of the mark's width.
  ///
  /// Exposed so anything drawing *around* the mark can be concentric with it.
  /// The onboarding's share sheet puts a selection ring on it, and a ring with
  /// a radius picked off the radius scale is a rounder shape around a squarer
  /// one — visible at 38px as a ring that does not fit its icon.
  static const double cornerRatio = _backdropRadius;

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
