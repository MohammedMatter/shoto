import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';
import 'package:shoto/features/onboarding/presentation/widgets/shot_card.dart';

/// The first five seconds of the app: **a fall of screenshots, swallowed.**
///
/// Twenty-six drawn screenshots come down from above the frame, converge, and
/// go into the mark one after another. Nothing is narrated while it happens.
/// By the time the first word appears the app has already said what it is, and
/// the sentence under the headline is confirming something rather than
/// introducing it.
///
/// ## Why the cards fall into the mark rather than fan out of it
///
/// The obvious version of this animation is the reverse — the mark opens and
/// the screenshots spill out, the way a hundred app intros present a feature
/// list. That gets the direction of the product backwards. Screenshots are not
/// something Shoto gives you; they are something you already have too many of,
/// and the app is where they *stop*. So the traffic on this screen only ever
/// goes one way, and the last thing left on the screen is the thing that
/// caught them all.
///
/// It is also the only claim in the whole introduction that is made before any
/// text can be read, which is why it has to be the true one.
///
/// ## The handoff
///
/// The welcome is not a second screen. The mark is one widget for the entire
/// sequence: it sits low while it is catching (there has to be room above it
/// for things to fall *from*), rises as the fall thins out, and keeps rising
/// into its resting place while the headline, the sentence and the button come
/// up underneath it. A cross-fade between two screens here would throw away
/// the one object the eye has been locked on for five seconds.
///
/// ## Determinism
///
/// The pile is generated once from a fixed seed and held in a `static final`.
/// A live `Random` would deal a different fall on every launch, which sounds
/// like variety and is actually two problems: the screen could never be
/// golden-tested, and somebody replaying the introduction from Settings would
/// not be watching the thing they remembered.
///
/// Reduced motion jumps to the end: the welcome, complete, with no fall. The
/// rule in `app_motion.dart` is that motion is a gift on something seen once —
/// but a person who has asked the system for less of it has already declined
/// the gift.
class OnboardingOpening extends StatefulWidget {
  /// The introduction proper is ready to begin.
  final VoidCallback onStart;

  /// Out of the whole thing, from the button in the corner.
  final VoidCallback onSkip;

  const OnboardingOpening({
    super.key,
    required this.onStart,
    required this.onSkip,
  });

  @override
  State<OnboardingOpening> createState() => _OnboardingOpeningState();
}

class _OnboardingOpeningState extends State<OnboardingOpening>
    with SingleTickerProviderStateMixin {
  /// The whole opening, from the first card entering the frame to the button
  /// settling. Far longer than anything `app_motion.dart` allows for an
  /// interaction, for the same reason the sign-in entrance is: nothing here is
  /// a response to a tap, and the only deadline is that **Skip is on screen
  /// and pressable from the first frame**.
  static const Duration _opening = Duration(milliseconds: 5200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _opening,
  );

  /// The fall. Ends well before the controller does — the last card is inside
  /// the mark at 0.66, and everything after that is the screen composing
  /// itself around what is left.
  static const Interval _fall = Interval(0, 0.66);

  /// The mark's climb into its resting place, and the copy arriving under it.
  static const Interval _arrive = Interval(0.66, 0.90, curve: AppMotion.drawer);
  static const Interval _title = Interval(
    0.72,
    0.93,
    curve: AppMotion.standard,
  );
  static const Interval _body = Interval(0.78, 0.97, curve: AppMotion.standard);
  static const Interval _action = Interval(0.83, 1, curve: AppMotion.standard);

  /// The faint field behind the welcome — the library, implied. Comes in only
  /// once the fall is over, so it never competes with the cards that are still
  /// moving.
  static const Interval _field = Interval(0.70, 1);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: the reduced-motion preference comes from the media
    // query, which is not resolved that early.
    if (_started) return;
    _started = true;

    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// True once the fall is over and the welcome owns the screen. Drives the
  /// one thing that cannot be a fraction: whether Skip or the button is the
  /// live control.
  bool get _welcome => _controller.value >= _arrive.begin;

  /// The whole opening, and the reason it can hold a frame budget.
  ///
  /// ## Everything that moves is a layer, and every frame is paint only
  ///
  /// The first version of this screen was written the obvious way — an
  /// `Align` per card with an animated `Alignment`, a `Transform.rotate`
  /// around a `Transform.scale`, and a full-screen `DecoratedBox` whose
  /// gradient centre moved. It ran, and it was heavy, for three reasons that
  /// are worth naming because they are the same three every time:
  ///
  /// 1. **An animated `Alignment` is a layout animation.** `Align` positions
  ///    its child during layout, so a new alignment every frame marks the
  ///    subtree dirty for layout, not just paint — eleven cards' worth, sixty
  ///    times a second, for five seconds. The fix is to keep the alignment
  ///    constant and move the card with a matrix instead: `RenderTransform`
  ///    only ever calls `markNeedsPaint`. The pose is still authored in the
  ///    same units, converted here with the *same formula* `Align` would have
  ///    used, so the composition is identical to the pixel.
  /// 2. **A moving gradient repaints every pixel it covers.** A radial
  ///    gradient across the whole screen is a per-pixel shader, and moving its
  ///    centre re-evaluates all of it every frame. It was cut down to a fixed
  ///    square painted once into its own layer, and has since been deleted
  ///    outright — see [_MarkEdge] for why a wide falloff was the wrong
  ///    instrument in the first place, and what carries its job now.
  /// 3. **Three render objects per card, and none of them a boundary.** Rotate
  ///    and scale and translate compose into one matrix, so they are one
  ///    `Transform` rather than three; and the card underneath is a
  ///    `RepaintBoundary`, so its dozen little boxes are rasterised once and
  ///    the whole per-frame cost of a falling screenshot becomes a matrix and
  ///    an alpha applied to a texture.
  ///
  /// The card subtrees, the mark and the field are all built **once per build
  /// of this widget** and captured by the builder below, so the twenty-six
  /// `ShotCard`s are not reconstructed sixty times a second either.
  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[
      for (int i = 0; i < _pile.length; i++)
        RepaintBoundary(child: ShotCard(seed: _pile[i].seed)),
    ];
    final Widget mark = RepaintBoundary(child: ShotoBrandMark(size: _markSize));
    const Widget library = RepaintBoundary(child: _Library());

    // Read once. `ShotCard.size` goes through `ScreenUtil` on every call, and
    // this is wanted eleven times a frame.
    final Size card = ShotCard.size;
    final double markSize = _markSize;

    // Built here, once, and passed into the frame builder as the same instance
    // every time — see [_Welcome] for why that is the whole fix for the hitch
    // when the button used to appear.
    final Widget welcome = _Welcome(
      controller: _controller,
      title: _title,
      body: _body,
      action: _action,
      onStart: widget.onStart,
    );

    // The box is measured once, out here, so the pose-to-pixel conversion
    // below is arithmetic rather than layout.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints room) {
        final Size box = Size(room.maxWidth, room.maxHeight);

        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            final double t = _controller.value;
            final double fall = _fall.transform(t);
            final double arrive = _arrive.transform(t);

            // Where the cards are going, and where the mark is. One number,
            // used by both, so a card can never be swallowed by a mark that has
            // already moved on.
            final double sink = _sinkY(fall, arrive);

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Opacity(
                  opacity: _field.transform(t) * _fieldPeak,
                  child: library,
                ),

                for (int i = 0; i < _pile.length; i++)
                  ..._falling(_pile[i], fall, sink, box, card, cards[i]),

                // Above the cards on purpose: they go *behind* the mark on the
                // way in, which is the whole difference between being caught
                // and being covered up.
                _Placed(
                  matrix: Matrix4.translationValues(
                    0,
                    _alignToPixels(sink, box.height, markSize),
                    0,
                  ),
                  child: mark,
                ),

                // And the mark's own edge over the top of it, brightening as
                // the pile comes in. See [_MarkEdge].
                _Placed(
                  matrix: Matrix4.translationValues(
                    0,
                    _alignToPixels(sink, box.height, markSize),
                    0,
                  ),
                  child: _MarkEdge(size: markSize, lit: fall),
                ),

                welcome,

                // Skip outlives the fall by a moment and then gets out of the
                // way: once there is a button that says what happens next, a
                // second control offering to leave is noise.
                Positioned(
                  top: 4.h,
                  right: 8.w,
                  child: IgnorePointer(
                    ignoring: _welcome,
                    child: Opacity(
                      opacity: (1 - arrive).clamp(0.0, 1.0),
                      child: TextButton(
                        onPressed: widget.onSkip,
                        child: Text(
                          context.l10n.onbSkip,
                          style: context.text.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// A pose's `y`, in the pixels `Align` would have put it at.
  ///
  /// This is `Align`'s own arithmetic, kept because the poses were authored
  /// against it and a different mapping would silently re-compose every stage
  /// of the fall. The child is measured **unscaled** — the scale is applied by
  /// the matrix afterwards, about the card's own centre, exactly as the old
  /// `Transform.scale` inside the `Align` did.
  static double _alignToPixels(double y, double extent, double childExtent) =>
      y * (extent - childExtent) / 2;

  /// How far down the mark sits, in `Alignment` units.
  ///
  /// Three positions, not two. It starts **low** — a fall needs somewhere to
  /// fall from, and a mark parked in the middle of the screen halves the
  /// runway. It rises as the pile thins, which is the fall's own progress read
  /// off the one object that stays. Then it climbs to its resting place above
  /// the headline.
  double _sinkY(double fall, double arrive) {
    final double caught = _lerp(0.62, 0.12, AppMotion.standard.transform(fall));
    return _lerp(caught, -0.40, arrive);
  }

  /// One card, mid-fall — or nothing at all, before it starts and after it is
  /// swallowed.
  ///
  /// Returned as a list so the common case costs an empty list rather than a
  /// `SizedBox` in the tree: at any moment most of the pile has either not
  /// left yet or is already inside the mark.
  List<Widget> _falling(
    _Fall card,
    double fall,
    double sink,
    Size box,
    Size cardSize,
    Widget child,
  ) {
    final double raw = ((fall - card.delay) / card.span);
    if (raw <= 0 || raw >= 1) return const <Widget>[];

    // Position decelerates into the mark and nothing else.
    //
    // **An ease-in here was the first version and it was wrong**, for a reason
    // worth writing down: a card spends its first third above the top of the
    // frame, so a curve that starts slowly spends that time moving a card
    // nobody can see and then hurries it across the part they can. Measured on
    // the golden, six of the eleven cards in the air at the densest moment
    // were off screen. The fall has to be quick where it is invisible and slow
    // where it is not.
    final double p = Curves.easeOutSine.transform(raw);

    // Scale is on its own, later curve. Held near full size for most of the
    // journey and then collapsing — a card that shrinks evenly all the way
    // down reads as *receding*, and this one is being *taken*.
    final double s = Curves.easeInCubic.transform(raw);
    final double size = _lerp(card.scale, 0.06, s);

    // In over the first sliver — cards whose lane starts on screen would
    // otherwise appear from nothing — and out over the last, which is the card
    // passing into the mark. Exactly 1 in between, which matters: `RenderOpacity`
    // is a straight pass-through at full alpha, so for most of a card's life
    // there is no compositing cost at all.
    final double opacity =
        (raw / 0.06).clamp(0.0, 1.0) *
        (1 - ((raw - 0.86) / 0.14).clamp(0.0, 1.0));

    // Translate, then rotate, then scale — the same order the three nested
    // widgets applied, folded into one matrix so the card costs one render
    // object instead of three.
    final Matrix4 matrix =
        Matrix4.translationValues(
            _alignToPixels(_lerp(card.lane, 0, p), box.width, cardSize.width),
            _alignToPixels(
              _lerp(card.from, sink, p),
              box.height,
              cardSize.height,
            ),
            0,
          )
          // Straightening as they go. The pile is crooked; what Shoto holds is
          // square. That is the entire product, drawn.
          ..rotateZ(_lerp(card.turns, 0, p) * 2 * math.pi)
          // `scaleByDouble` rather than `scale`: the latter is deprecated in
          // this vector_math, and the four-argument form is what it forwards to.
          ..scaleByDouble(size, size, 1, 1);

    return <Widget>[_Placed(matrix: matrix, opacity: opacity, child: child)];
  }

  /// The mark's size on this screen. Constant: it moves, it does not grow.
  /// Anything that both travels and resizes reads as a zoom, and a zoom on a
  /// logo is the tell of a template.
  double get _markSize => 84.w;

  /// How present the field behind the welcome is allowed to get.
  ///
  /// Texture, not scenery. At 0.16 — the first attempt — every card behind the
  /// headline was legible as a card, and the screen read as a wireframe
  /// wallpaper with a logo on it. The test is whether you can tell there is
  /// something back there without being able to say what.
  static const double _fieldPeak = 0.07;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// The fall, dealt once.
  ///
  /// Twenty-six cards over a 0.66 window, each taking about a third of it, so
  /// there are always six or seven in the air: enough to read as a stream,
  /// few enough that individual cards can be followed. The tail is deliberately
  /// sparse — the last four fall alone, which is what makes the end of the
  /// sequence feel like an end rather than a cut.
  static final List<_Fall> _pile = _deal();

  static List<_Fall> _deal() {
    const int count = 26;
    final math.Random random = math.Random(20260812);
    final List<_Fall> pile = <_Fall>[];

    for (int i = 0; i < count; i++) {
      // Front-loaded. Squaring the position in the pile spends most of the
      // window on the first two thirds of the cards and leaves the last few
      // spread over a long tail.
      final double f = i / count;
      pile.add(
        _Fall(
          // Lanes reach past both edges. A fall that respects the screen's
          // margins looks like a list animating in.
          lane: -1.25 + random.nextDouble() * 2.5,
          // Just above the frame, and no further. Anything higher is time the
          // card spends falling where it cannot be seen — with eleven of them
          // in the air, that is the difference between a stream and a trickle.
          from: -1.15 - random.nextDouble() * 0.55,
          delay: (f * f * 0.46 + f * 0.26).clamp(0.0, 0.72),
          span: 0.26 + random.nextDouble() * 0.10,
          turns: (random.nextDouble() - 0.5) * 0.14,
          // Big. These are the closest thing to the camera on the screen and
          // the mark is what they vanish into, so the size gap between the two
          // is doing most of the work.
          scale: 1.05 + random.nextDouble() * 0.75,
          seed: i + 1,
        ),
      );
    }

    return pile;
  }
}

/// One card's whole journey, in numbers. See `_deal`.
@immutable
class _Fall {
  /// Start x, in `Alignment` units — past ±1 is off the side of the screen.
  final double lane;

  /// Start y. Always above -1, which is the top edge.
  final double from;

  /// When this card leaves, as a fraction of the fall window.
  final double delay;

  /// How much of the window this card's own fall takes.
  final double span;

  /// Rotation at the start, in turns. Unwound on the way down.
  final double turns;

  /// Size at the start. Ends at nothing, inside the mark.
  final double scale;

  /// Which drawn screenshot this is. See [ShotCard].
  final int seed;

  const _Fall({
    required this.lane,
    required this.from,
    required this.delay,
    required this.span,
    required this.turns,
    required this.scale,
    required this.seed,
  });
}

/// Anything that moves during the opening, moved the cheap way.
///
/// A **constant** alignment, so the `Stack` never marks this child dirty for
/// layout, and a matrix that carries the whole pose — `RenderTransform` only
/// ever calls `markNeedsPaint`. The child below is always a `RepaintBoundary`,
/// which is what turns the opacity into a composited layer property instead of
/// a `saveLayer` over live paint.
class _Placed extends StatelessWidget {
  final Matrix4 matrix;
  final double opacity;
  final Widget child;

  const _Placed({required this.matrix, required this.child, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Transform(
        transform: matrix,
        alignment: Alignment.center,
        // Skipped outright at full alpha. `RenderOpacity` is a pass-through at
        // 255 anyway, but not building the widget keeps one render object out
        // of the tree for the whole middle of every card's fall.
        child: opacity >= 1
            ? child
            : Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
      ),
    );
  }
}

/// **There used to be a pool of light behind the mark and it has been
/// deleted.** It is the third time this app has removed the same object, and
/// the reason is worth writing down once more because it is arithmetic rather
/// than taste.
///
/// It was a white radial gradient, peak alpha 0.16, on a square as wide as the
/// screen — a radius of about 223 logical pixels on a 360pt phone. White at
/// 0.16 over `AppPalette.canvasDark` (`#111213`) lands on `#373838`: **thirty-
/// eight levels of grey, spread over two hundred and twenty-three pixels.**
/// That is one 8-bit step every six pixels, and a step every six pixels in a
/// smooth falloff is not a falloff, it is a set of **concentric rings** — which
/// is exactly what it looked like on an OLED panel, and exactly what got it
/// reported. No stop count fixes that; the banding is the bit depth meeting a
/// gradient stretched too far, and the only cures are making the ramp short
/// enough that a step is under a pixel, or dithering it.
///
/// The app has already had this argument twice and settled it both times:
/// `app_colors.dart` deleted every shadow in the codebase because a soft dark
/// shape on near-black reads as *a smudge*, and `stage_canvas.dart` deleted
/// the tinted wash behind the onboarding pile for being **visibly a disc**.
/// This was the same object wearing the app's own logo.
///
/// ## What it was actually for, and what does that job now
///
/// One real job: `AppBrand.ink` is `#121212` and the canvas is `#111213`, one
/// level apart, so the mark's slab has *no edge at all* of its own and would
/// otherwise be three paper cards floating in a void.
///
/// So the light moved onto the object — the same move `ShotCard` made when the
/// wash came out of the stage, and the one device `app_colors.dart` sanctions:
/// "a frosted panel gets a lit top edge instead of a shadow underneath, which
/// is depth by what the surface reflects rather than by what it blocks."
///
/// [_MarkEdge] is a **one-pixel stroke**. A one-pixel stroke cannot band —
/// there is no distance across which a step can become a ring — and it gives
/// the slab a real edge instead of standing it in a cloud.
///
/// ## And it kept the narrative the glow was carrying
///
/// The old light came up from 0.35 to full as the pile fell, so the screen
/// brightened as the mark caught things. The edge does the same, on the object
/// that is doing the catching: the mark starts nearly bare and gathers light
/// with every screenshot it swallows, so by the last card it is the brightest
/// thing on a black screen — because it is holding all of them.
class _MarkEdge extends StatelessWidget {
  final double size;

  /// How far through the fall this is, 0 to 1.
  final double lit;

  const _MarkEdge({required this.size, required this.lit});

  @override
  Widget build(BuildContext context) {
    // Dark mode only. In light mode the slab is a near-black tile on `#F4F4F4`
    // and needs no help being seen — the same reason [ShotCard] only rims its
    // cards on dark, since white on paper is nothing at all. The light-mode
    // half of the old glow was a grey disc on a bright page, which had no job
    // to do and did it visibly.
    if (!context.colors.isDark) return SizedBox.square(dimension: size);

    final double t = lit.clamp(0.0, 1.0);
    // The slab's own corner, so the edge traces the shape rather than a shape
    // near it.
    final BorderRadius radius = BorderRadius.circular(
      size * ShotoBrandMark.cornerRatio,
    );

    return IgnorePointer(
      // The whole perimeter, faintly: a top edge alone leaves the bottom of
      // the tile dissolving into the canvas, and a logo with no bottom reads
      // as a rendering fault rather than as light from above.
      child: GlassRim(
        borderRadius: radius,
        // Not the default 44: this is a small object, and a falloff longer
        // than the thing it is lighting turns the rim into a full outline.
        falloff: size * 0.42,
        color: Colors.white.withValues(alpha: 0.06 + 0.13 * t),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.045 + 0.055 * t),
            ),
          ),
          child: SizedBox.square(dimension: size),
        ),
      ),
    );
  }
}

/// What the mark caught, implied rather than shown.
///
/// A still field of cards at a sixth of full strength, behind everything. It
/// is not a gallery and must never resolve into one — the moment a person can
/// make out an individual screenshot here they will try to read it instead of
/// the headline.
class _Library extends StatelessWidget {
  const _Library();

  /// Hand-placed rather than dealt: this one is a composition, and the gaps
  /// are where the headline and the button will land.
  static const List<Offset> _spots = <Offset>[
    Offset(-0.86, -0.92),
    Offset(-0.12, -1.02),
    Offset(0.72, -0.86),
    Offset(-0.98, -0.24),
    Offset(0.94, -0.18),
    Offset(-0.78, 0.46),
    Offset(0.86, 0.42),
    Offset(-0.22, 0.94),
    Offset(0.58, 1.02),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          for (int i = 0; i < _spots.length; i++)
            Align(
              alignment: Alignment(_spots[i].dx, _spots[i].dy),
              child: Transform.rotate(
                angle: (i.isEven ? 0.03 : -0.04) * 2 * math.pi,
                child: Transform.scale(
                  scale: 1.35,
                  child: ShotCard(seed: i + 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The headline, the sentence and the button — arriving in that order.
///
/// Anchored to the bottom of the screen rather than laid out under the mark:
/// the mark's resting place is set by [_OnboardingOpeningState._sinkY] in
/// `Alignment` space, and a column that tried to sit under it would have to
/// know that number. This way the two halves of the screen are independent,
/// and a taller phone gives its extra height to the gap between them, which is
/// where it belongs.
///
/// ## Built once, at the start, and never rebuilt
///
/// This whole column is constructed a single time and handed to the opening's
/// `Stack` as the same widget instance every frame, so Flutter's reconciliation
/// walks straight past it. Only the three [_Rise] wrappers listen to the
/// controller, and each of those rebuilds nothing but an opacity and an offset
/// around a child it was given.
///
/// **The first version faded each block in by not building it at all until its
/// interval opened, and that is what the lag was.** A block appearing meant
/// inflating it for the first time — for the button, that is a gradient, a
/// `PressableScale` with its own controller and an `AnimatedSwitcher` — and
/// then relaying out the column around a child that had just gone from zero
/// height to its full height. All of that landed on one frame, in the middle
/// of an animation, three times over. Mounting the column from the first frame
/// pays that cost once, while the screen is still black and nothing is
/// competing for the budget, and leaves the arrival as pure compositing.
class _Welcome extends StatelessWidget {
  final Animation<double> controller;
  final Interval title;
  final Interval body;
  final Interval action;
  final VoidCallback onStart;

  const _Welcome({
    required this.controller,
    required this.title,
    required this.body,
    required this.action,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Rise(
                controller: controller,
                interval: title,
                child: Text(
                  context.l10n.authWelcome,
                  textAlign: TextAlign.center,
                  style: context.text.displayLarge,
                ),
              ),
              SizedBox(height: 12.h),
              _Rise(
                controller: controller,
                interval: body,
                child: Text(
                  context.l10n.onbWelcomeBody,
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: 36.h),
              _Rise(
                controller: controller,
                interval: action,
                child: PrimaryButton(
                  label: context.l10n.onboardingCta,
                  onPressed: onStart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One block of the welcome arriving: a fade, and a short lift.
///
/// The child is passed through [AnimatedBuilder]'s `child` slot, so it is built
/// once and only the two wrappers around it are rebuilt per frame. Under it is
/// a [RepaintBoundary], which is what lets the opacity be a property of an
/// already-rasterised layer instead of a `saveLayer` over live paint — and the
/// button is a gradient with text on it, which is not something to be
/// re-rasterising sixty times a second.
///
/// The gate matters as much as the animation: an [Opacity] of zero still takes
/// hits, so without it the invisible button would be catching taps at the
/// bottom of the screen through the entire fall.
class _Rise extends StatelessWidget {
  final Animation<double> controller;
  final Interval interval;
  final Widget child;

  const _Rise({
    required this.controller,
    required this.interval,
    required this.child,
  });

  static const double _travel = 16;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: RepaintBoundary(child: child),
      builder: (BuildContext context, Widget? child) {
        final double t = interval.transform(controller.value);
        return IgnorePointer(
          ignoring: t < 0.999,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * _travel),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
