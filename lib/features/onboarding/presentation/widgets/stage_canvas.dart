import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_stages.dart';
import 'package:shoto/features/onboarding/presentation/widgets/shot_card.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';

/// The nine cards, and whatever the current stage puts beside them.
///
/// One `Stack`, nine children, and an animation that moves them from where
/// they were to where the new stage says they should be. There is no page
/// view here and no cross-fade between screens: **the same nine widgets are
/// alive from the first stage to the last**, which is the entire idea. You
/// are not being shown four pictures of a product; you are watching your own
/// pile of screenshots be dealt with.
class StageCanvas extends StatelessWidget {
  final List<CardPose> from;
  final List<CardPose> to;
  final StageProp prop;

  /// 0 while the cards are still in their old arrangement, 1 once they have
  /// arrived in the new one.
  final Animation<double> progress;

  const StageCanvas({
    super.key,
    required this.from,
    required this.to,
    required this.prop,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, Widget? child) {
        // Resolved once and shared: the wash is derived from exactly the
        // poses the cards are drawn at, so the light cannot drift out of step
        // with them mid-flight.
        final List<CardPose> poses = [
          for (int i = 0; i < OnboardingStage.cardCount; i++)
            CardPose.lerp(from[i], to[i], _t(i)),
        ];

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            // Behind the cards: whatever this stage is about.
            Positioned.fill(child: child!),
            for (int i = 0; i < OnboardingStage.cardCount; i++)
              _PosedCard(index: i, pose: poses[i], focus: _focus(poses)),
          ],
        );
      },
      // **Built once per stage, not once per frame.** A prop does not read the
      // cards' progress — [_ShareSheetProp] runs its own entrance — so it goes
      // through the builder's `child` slot and Flutter walks straight past it
      // sixty times a second.
      //
      // Clipped to the stage, which the cards deliberately are not: a prop
      // that slides in from below has to have somewhere below to come from,
      // and without this the share sheet would travel over the headline
      // underneath the stage on its way up.
      child: ClipRect(child: _Prop(prop: prop)),
    );
  }

  /// **How gathered the pile is right now**, 0 when scattered and 1 when
  /// stacked — the one number the lighting needs to know.
  ///
  /// The mean distance of the cards from their own centroid, mapped onto the
  /// range the stages actually produce: the opening heap sits near 0.75 and the
  /// filed stack near 0.20. Both ends were measured rather than picked, and the
  /// result is clamped so a stage authored outside that range degrades to the
  /// nearest sensible light instead of an extreme one.
  ///
  /// Derived rather than declared, which is the part worth keeping from the
  /// thing this replaced: nothing has to be authored per stage, and a pose
  /// added or re-timed later gets correct lighting without anyone remembering
  /// to update it.
  static double _focus(List<CardPose> poses) {
    double weight = 0;
    double cx = 0;
    double cy = 0;
    for (final CardPose pose in poses) {
      final double w = pose.opacity.clamp(0.0, 1.0);
      if (w <= _present) continue;
      weight += w;
      cx += pose.x * w;
      cy += pose.y * w;
    }
    if (weight <= 0) return 0;
    cx /= weight;
    cy /= weight;

    double spread = 0;
    for (final CardPose pose in poses) {
      final double w = pose.opacity.clamp(0.0, 1.0);
      if (w <= _present) continue;
      final double dx = pose.x - cx;
      final double dy = pose.y - cy;
      spread += w * math.sqrt(dx * dx + dy * dy);
    }
    spread /= weight;

    return 1 - ((spread - 0.20) / 0.55).clamp(0.0, 1.0);
  }

  /// Below this a card has effectively left and should not pull the light
  /// toward wherever it is drifting off to.
  static const double _present = 0.02;

  /// Each card's own progress through the move.
  ///
  /// Cards do not all leave at once — the one nearest the front goes first
  /// and the rest follow a frame or two behind, which is what makes a group
  /// of objects read as a group rather than as a single sliding sheet. The
  /// stagger is deliberately small and the *whole* rearrangement, tail
  /// included, still finishes inside the app's longest allowed duration.
  double _t(int index) {
    const double step = 0.05;
    final double start = index * step;
    final double span = 1 - step * (OnboardingStage.cardCount - 1);
    return ((progress.value - start) / span).clamp(0.0, 1.0);
  }
}

/// **There used to be a big tinted radial gradient here and it has been
/// deleted.** It is worth saying what it was and why it went, because the idea
/// behind it was right and only the instrument was wrong.
///
/// It painted `colors.primary` as a wide radial wash behind the pile, centred
/// on the cards' centroid and tightening as they gathered — chaos to focus,
/// told by the lighting. Three things killed it:
///
/// 1. **Its own stated rule stopped being enforceable.** The note on it said
///    the wash must be "the same hue, never a second one", so that a card's lit
///    search line — [AppPalette.secondary] — stays the only colour on screen.
///    That held while the accent was a fixed teal and secondary was a slate
///    blue. The accent is now one of twenty-one hues the user picks, and one of
///    them *is* slate: choose it and the wash and the search hit become the
///    same colour, which is precisely the collision the rule existed to
///    prevent. Nothing in the code could notice.
///
/// 2. **Its two alphas were calibrated against one colour.** 0.40 on dark and
///    0.17 on light were measured, carefully, for teal. A saturated ember or
///    fuchsia at the same alpha is a different object. Twenty-one hand-tuned
///    pairs is not a system, and one pair for twenty-one hues is not either.
///
/// 3. **It was visibly a disc.** `RadialGradient.radius` is a fraction of the
///    box's *shortest* side, which on a portrait stage is its width — so the
///    falloff completed well inside the frame vertically and the light had an
///    edge you could point at. The file already fought this once, with a
///    35%-of-height bleed box built specifically to push the ring off screen.
///    A hack that exists to hide the shape of the thing is the thing telling
///    you it is the wrong shape.
///
/// And underneath all three: a low-alpha colour laid over near-black does not
/// read as light. It reads as a smudge — which is the exact word
/// `app_colors.dart` uses when it explains why this app deleted every shadow
/// it had.
///
/// What replaced it is in [ShotCard]: the light moved onto the cards, where it
/// is achromatic, has no edge to see, and cannot collide with the one colour on
/// screen that means something. The narrative survived the move — see
/// [StageCanvas._focus], which is the same centroid-and-spread calculation the
/// wash used, now feeding a rim instead of a cloud.

class _PosedCard extends StatelessWidget {
  final int index;
  final CardPose pose;

  /// How gathered the whole pile is — see [StageCanvas._focus].
  final double focus;

  const _PosedCard({
    required this.index,
    required this.pose,
    required this.focus,
  });

  /// **Where a card's share of the light comes from.**
  ///
  /// Half the scene and half the card. The scene half is [focus], so the whole
  /// pile brightens as it is filed. The card half is its own [CardPose.scale],
  /// which in this composition is depth — the poses put the nearest cards at
  /// about 1.0 and the ones pushed back at about 0.8 — so a card standing
  /// forward catches more than one behind it.
  ///
  /// That second half is the part a gradient behind the pile could never do.
  /// A wash lights the *gaps* between cards; this lights the cards, and lights
  /// them by how near they are, which is the only reason a flat stack of
  /// rectangles reads as having depth at all.
  double get _lit {
    final double depth = ((pose.scale - 0.80) / 0.25).clamp(0.0, 1.0);
    return (0.45 * depth + 0.55 * focus).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (pose.opacity <= 0.01) return const SizedBox.shrink();

    return Align(
      alignment: Alignment(pose.x, pose.y),
      child: Opacity(
        opacity: pose.opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: pose.turns * 2 * 3.1415926535,
          child: Transform.scale(
            scale: pose.scale,
            // Repaint boundary per card: nine transforms that all change
            // every frame, and without this each one dirties the whole
            // canvas including the prop behind it.
            child: RepaintBoundary(
              child: ShotCard(seed: index + 1, mark: pose.mark, lit: _lit),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stage's supporting cast — a folder, a search field, the Pro list.
///
/// Switched rather than rebuilt so it fades between stages instead of
/// snapping. Everything here is drawn with the app's own tokens, so what the
/// onboarding shows is literally what the app looks like.
class _Prop extends StatelessWidget {
  final StageProp prop;

  const _Prop({required this.prop});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.normal),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      child: switch (prop) {
        StageProp.none => const SizedBox.shrink(key: ValueKey('none')),
        StageProp.shareSheet => const _ShareSheetProp(
          key: ValueKey('shareSheet'),
        ),
        StageProp.folders => const _FoldersProp(key: ValueKey('folders')),
        StageProp.search => const _SearchProp(key: ValueKey('search')),
        StageProp.safeShare => const _SafeShareProp(key: ValueKey('safeShare')),
      },
    );
  }
}

/// The system share sheet, **coming up**, with Shoto already chosen.
///
/// **This is the app's front door and the only one**, so it is the first thing
/// the introduction shows. A person who finishes the sequence without knowing
/// that screenshots arrive by being *shared* has an empty library and no idea
/// why.
///
/// Drawn as the sheet rather than described as a step, and drawn small — the
/// point is recognition, not instruction. Anybody who has used a phone knows
/// this shape, and the only new information on it is which target to look for,
/// which is why that one is the only one carrying a name, a mark and a ring.
///
/// ## What was here before, and why four grey discs had to go
///
/// The row used to be four 40px circles: three filled flat with
/// [AppPalette.surfaceElevated] and one carrying the mark. Three problems, and
/// the first is the one that mattered.
///
/// 1. **A blank filled disc with a blank filled bar under it is the universal
///    drawing of a *skeleton loader*.** Every app on the phone uses exactly
///    that shape to say "this has not arrived yet". So the first stage of the
///    introduction — the screen that has to look more finished than any other
///    in the product — was showing three placeholders and a caption bar, and
///    read as a screen still waiting for its data. Nothing else on the stage
///    was wrong; this alone made the whole thing look unbuilt.
/// 2. **They were the loudest thing on the stage.** `surfaceElevated` is the
///    top of the elevation ramp, and the pile of cards above is drawn in
///    `surface` with a hairline border. Three discs at the top of the ramp
///    beside nine objects near the bottom of it puts the eye on the one part
///    of the picture that means nothing.
/// 3. **They were circles.** `AppRadius.md` is 18 on a 40px box, which is a
///    circle in everything but name — and the row it belongs to is a row of
///    *app icons*, which on this phone and on every Android since adaptive
///    icons are rounded squares.
///
/// What replaces them is structure rather than content: outlined tiles, no
/// fill, no captions, at the same size as Shoto's own. They give the row its
/// rhythm and say "there are other apps here", and they do not ask to be
/// looked at.
///
/// ## The two things it now does that a still picture could not
///
/// **It arrives the way a share sheet arrives.** It comes up from under the
/// stage on [AppMotion.drawer] — the curve this app keeps for a surface that
/// travels — because the single most recognisable fact about a share sheet is
/// not what is on it, it is that it *rises from the bottom of the screen*. A
/// sheet that is simply already there is a picture of a sheet.
///
/// **The row runs off both edges.** The stage's own claim is "any app", and a
/// row of exactly four targets sitting inside a box quietly contradicts it. The
/// two outermost tiles are cut by the sheet's sides, which is what a phone's
/// share row actually looks like and says *there are more of these than fit*
/// without a word.
///
/// The entrance is its own controller rather than the stage's, and that is
/// deliberate: the outgoing copy of this widget lives on inside the
/// [AnimatedSwitcher] for a moment after the stage has changed, and a stage
/// controller that has already reset to zero would snap it back down through
/// the floor as it faded.
class _ShareSheetProp extends StatefulWidget {
  const _ShareSheetProp({super.key});

  @override
  State<_ShareSheetProp> createState() => _ShareSheetPropState();
}

class _ShareSheetPropState extends State<_ShareSheetProp>
    with SingleTickerProviderStateMixin {
  /// **Three things in a row, and the order is the sentence.** The sheet comes
  /// up, Shoto is picked, and a screenshot goes in — which is exactly what the
  /// headline above says happens and the only way anything ever gets into this
  /// app.
  ///
  /// Far longer than [AppMotion.sheet], and allowed to be. The ceiling in
  /// `app_motion.dart` is about a user who has tapped something and is waiting
  /// on the end of the animation; nobody is waiting on this one, and it is
  /// seen once. It is still the longest thing on the stage, so it goes last:
  /// the copy underneath has finished arriving at 620ms and the eye is free.
  static const Duration _entrance = Duration(milliseconds: 1250);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _entrance,
  );

  /// The sheet's travel. Starts a beat late so the cards above are already
  /// moving when it appears — the pile is the subject and the sheet is what
  /// answers it, and answering first would be the wrong order.
  static const Interval _rise = Interval(0.02, 0.30, curve: AppMotion.drawer);

  /// The ring landing on the chosen target, after the sheet has stopped.
  static const Interval _chosen = Interval(
    0.22,
    0.46,
    curve: AppMotion.standard,
  );

  /// The screenshot leaving the pile and going in.
  static const Interval _handover = Interval(0.42, 0.96);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: the reduced-motion preference is a media query, which
    // is not resolved that early. Same reason as [OnboardingOpening].
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

  /// Every target's icon, Shoto's included.
  ///
  /// **The same size for all five, which is the whole reason the row reads as
  /// a share sheet.** Making the chosen one bigger was tried and it stops
  /// being a system surface and becomes an advertisement — the ring says
  /// chosen, and it says it without touching the rhythm.
  static double get _tile => 38.w;

  /// Between targets. Set so five tiles come to a little wider than the sheet
  /// and the outer pair is cut by about a third.
  static double get _gap => 20.w;

  /// The sheet. Narrower than the stage on purpose — it is a phone's sheet
  /// seen at a distance, not this screen's own furniture.
  static double get _width => 252.w;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    // Built once and carried through the builder below, so the entrance costs
    // one transform per frame and nothing else.
    final Widget sheet = Container(
      width: _width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          // The grabber. Four pixels of it is the whole reason the shape
          // below reads as a sheet rather than as a card.
          Container(
            width: 32.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          SizedBox(height: 15.h),
          // The row is wider than the sheet and the sheet clips it, which is
          // the point. [OverflowBox] rather than letting a `Row` overflow: an
          // overflowing `Row` paints the framework's black-and-yellow warning
          // in a debug build, which is what the user is running.
          SizedBox(
            height: _tile + 6.h + 11.sp,
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    if (i > 0) SizedBox(width: _gap),
                    // **The chosen target's icon is not in the row.** It keeps
                    // the row's space and its name here, and the mark and its
                    // ring are painted further down the stack — above the card
                    // flying into them. That z-order is the entire difference
                    // between a screenshot being *taken by* Shoto and a
                    // screenshot sliding over the top of it, and it is the
                    // same order the opening uses for the same reason.
                    if (i == 2)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(dimension: _tile),
                          SizedBox(height: 6.h),
                          // A literal, like every other place the product
                          // names itself — see `app_version_block.dart`. It is
                          // a proper noun and it is spelled the same in all
                          // eight languages.
                          Text(
                            'Shoto',
                            maxLines: 1,
                            style: context.text.caption.copyWith(
                              color: colors.textPrimary,
                              fontSize: 8.sp,
                              height: 1,
                            ),
                          ),
                        ],
                      )
                    else
                      // Faint at the ends. The cut tiles are the ones saying
                      // "and more", and a cut edge is easier to read as an
                      // edge than as a broken drawing when it is quiet.
                      _ShareTarget(
                        size: _tile,
                        presence: i == 0 || i == 4 ? 0.45 : 0.8,
                      ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
        ],
      ),
    );

    // Deliberately not one of the pile's nine. Every seed from 1 to 9 is
    // already drawn on the stage, so re-using one would put the same
    // screenshot on screen twice and the hand-over would read as a copy being
    // made rather than as a thing being moved.
    //
    // **Fully lit, and that is not decoration — it is the only thing that
    // makes the flight visible at all.** A card and this sheet are both
    // `surface`, so the first version of this crossed the sheet as an
    // invisible object: a pixel diff of the frame found it exactly where the
    // arithmetic said it was, and 125 pixels of it differed from the frame
    // without it. [ShotCard.lit] is the app's own answer to that problem, and
    // it answers it correctly in both modes — on dark the card rises up the
    // elevation ramp and catches a rim, on light it takes a darker edge,
    // because a white card on a white sheet can only be separated by its
    // border. It is also true: this is the nearest object to the camera and
    // the one the whole stage is about.
    const Widget handed = RepaintBoundary(child: ShotCard(seed: 10, lit: 1));

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _controller,
            child: sheet,
            builder: (BuildContext context, Widget? child) {
              // A fraction of the sheet's *own* height, so the travel is
              // exactly "up from out of sight" on any screen without anybody
              // measuring it.
              final double t = _rise.transform(_controller.value);
              return FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: child,
              );
            },
          ),
        ),

        // Measured out here so the flight below is arithmetic rather than
        // layout — the same trade the opening makes for the same reason.
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints room) {
            final Widget chosen = RepaintBoundary(
              child: _ChosenTarget(size: _tile, arrival: _arrival),
            );

            return AnimatedBuilder(
              animation: _controller,
              child: handed,
              builder: (BuildContext context, Widget? child) => Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _flight(room.maxHeight, child!),
                  _chosenAt(room.maxHeight, chosen),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// The chosen target, put back exactly where the row left a hole for it.
  ///
  /// It travels with the sheet rather than after it: the extra offset is the
  /// same `1 - t` the [FractionalTranslation] above applies, in pixels, which
  /// is why [_sheetHeight] has to be known in advance. Anything less exact and
  /// the icon would swim inside its own row on the way up.
  Widget _chosenAt(double boxHeight, Widget chosen) {
    final double rise = _rise.transform(_controller.value);

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(0, _tileCentre(boxHeight) + (1 - rise) * _sheetHeight),
        child: chosen,
      ),
    );
  }

  /// The middle of the Shoto tile once the sheet has landed, measured from the
  /// middle of the stage. A sum of fixed boxes down from the sheet's top edge.
  double _tileCentre(double boxHeight) =>
      boxHeight / 2 - _sheetHeight + _rowTop + _tile / 2;

  Animation<double> get _arrival =>
      _controller.drive(CurveTween(curve: _chosen));

  /// The sheet's own height, in advance.
  ///
  /// Every box in it is a fixed size, so this is addition rather than
  /// measurement — and knowing it before layout is what lets the card below
  /// aim at the middle of a target the sheet has not finished delivering yet.
  double get _sheetHeight => 2 + _rowTop + _tile + 6.h + 11.sp + 14.h;

  /// From the sheet's top edge to the top of the icon row: the border, the
  /// clearance, the grabber and the gap under it.
  double get _rowTop => 10.h + 4.h + 15.h;

  /// **One screenshot leaving the pile and being taken into Shoto.**
  ///
  /// The one gesture the introduction has already taught: this is the fall
  /// from the opening, once, at the size of a share sheet — and it is the
  /// answer to the question that screen deliberately left open. Twenty-six
  /// screenshots went into the mark and nothing said how. This is how.
  ///
  /// It starts where the pile's centre card is standing and it starts
  /// *behind* it, because the prop is painted under the cards: for the first
  /// fraction of its flight it is hidden by the very card it is meant to have
  /// come from. Nothing is created on screen; something already in the pile
  /// leaves it.
  Widget _flight(double boxHeight, Widget card) {
    final double raw = _handover.transform(_controller.value);
    if (raw <= 0 || raw >= 1) return const SizedBox.shrink();

    // Where it comes from: the pose of the pile's centre card, converted the
    // way `Align` converts it — the child measured unscaled, since the scale
    // below is applied afterwards about the card's own centre.
    final double from = 0.34 * (boxHeight - ShotCard.size.height) / 2;

    // Where it goes: the middle of the Shoto tile, which the mark is painted
    // over the top of — so the last thing this card does is pass behind it.
    final double to = _tileCentre(boxHeight);

    // Decelerating into the target and nothing else, for the reason the
    // opening writes out at length: an ease-in spends its slow half where the
    // card is still hidden behind the pile and hurries the part that is
    // actually watched.
    final double p = Curves.easeOutSine.transform(raw);

    // Held near full size and then collapsing, on its own later curve. A card
    // that shrinks evenly the whole way reads as *receding*; this one is being
    // *taken*.
    final double scale = 0.72 - 0.62 * Curves.easeInCubic.transform(raw);

    // Out over the last stretch, which is the card passing into the tile.
    // Exactly 1 before that: `RenderOpacity` is a pass-through at full alpha,
    // so most of the flight costs no compositing at all.
    final double opacity = 1 - ((raw - 0.80) / 0.20).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.center,
      child: Transform(
        transform: Matrix4.translationValues(0, from + (to - from) * p, 0)
          ..scaleByDouble(scale, scale, 1, 1),
        alignment: Alignment.center,
        child: opacity >= 1 ? card : Opacity(opacity: opacity, child: card),
      ),
    );
  }
}

/// One of the other apps in the row.
///
/// An outline and nothing else. It is deliberately not *anything* — a drawn
/// glyph would be inventing somebody else's brand, and a filled shape is the
/// placeholder this replaced. What is left is the only true statement
/// available: there is an app here, and it is not the one you are looking for.
class _ShareTarget extends StatelessWidget {
  final double size;

  /// How present this one is allowed to be, 0 to 1.
  final double presence;

  const _ShareTarget({required this.size, required this.presence});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: presence,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // The share row on this phone is rounded squares, because every
            // Android icon since adaptive icons has been one. The circles that
            // used to be here were a radius token applied to a box small
            // enough that it closed.
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: context.colors.border),
          ),
        ),
      ),
    );
  }
}

/// Shoto in the share sheet, chosen — the icon and its ring, and nothing else.
///
/// Painted over the row rather than in it (the row holds the space and the
/// name), so the screenshot on its way in passes *behind* it.
///
/// The mark is the same size as every other icon in the row. Making the chosen
/// one bigger was tried and it stops being a system surface and becomes an
/// advertisement — the ring says chosen, and it says it without touching the
/// rhythm.
///
/// The ring settles onto the icon from very slightly too large, and that is
/// worth the code: a ring that fades in reads as a highlight somebody drew,
/// and a ring that contracts onto the icon reads as a selection *landing on
/// it*. It never starts from nothing, which is the rule this app's motion is
/// built on — things arrive from somewhere.
class _ChosenTarget extends StatelessWidget {
  final double size;

  /// 0 before the ring has arrived, 1 once it has settled.
  final Animation<double> arrival;

  const _ChosenTarget({required this.size, required this.arrival});

  /// How far outside the icon the ring sits.
  static double get _clearance => 4.w;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ShotoBrandMark(size: size),
          // Outside the icon's own box, so the row's spacing is set by the
          // icons and the ring cannot push its neighbours around.
          Positioned(
            left: -_clearance,
            top: -_clearance,
            right: -_clearance,
            bottom: -_clearance,
            child: AnimatedBuilder(
              animation: arrival,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // The mark's own corner plus the clearance, so the ring
                  // is concentric with the icon inside it rather than a
                  // rounder shape drawn around a squarer one.
                  borderRadius: BorderRadius.circular(
                    size * ShotoBrandMark.cornerRatio + _clearance,
                  ),
                  border: Border.all(color: context.colors.primary, width: 1.6),
                ),
              ),
              builder: (BuildContext context, Widget? child) {
                final double t = arrival.value;
                return Opacity(
                  opacity: t,
                  child: Transform.scale(scale: 1.12 - 0.12 * t, child: child),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Three folders, one of them named.
///
/// The named one is [AppLocalizations.onbFolderExample] — "Receipts" — because
/// a folder called "Folder 1" demonstrates a control and a folder called
/// "Receipts" demonstrates a *use*. The other two are left as shapes: a row of
/// three invented folder names is somebody else's filing system, and the
/// person looking at it has their own.
class _FoldersProp extends StatelessWidget {
  const _FoldersProp({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.92),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(end: i == 2 ? 0 : 8.w),
              child: _Folder(named: i == 0),
            ),
        ],
      ),
    );
  }
}

class _Folder extends StatelessWidget {
  final bool named;

  const _Folder({required this.named});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: named ? context.colors.borderSelected : context.colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 15.sp,
            color: named
                ? context.colors.primary
                : context.colors.iconSecondary,
          ),
          SizedBox(width: 7.w),
          if (named)
            Text(
              context.l10n.onbFolderExample,
              style: context.text.caption.copyWith(
                color: context.colors.textPrimary,
              ),
            )
          else
            Container(
              width: 26.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

/// The search field, with a word already in it.
///
/// The word is [AppLocalizations.onbSearchExample] — "receipt" — and it is the
/// same word as the named folder above for a reason: the two stages are one
/// argument seen twice. You filed it, and then you did not have to remember
/// where you filed it.
///
/// The caret is drawn but does not blink. A blinking cursor on a screen where
/// nine cards are already moving is a second clock, and `app_motion.dart` does
/// not allow two.
class _SearchProp extends StatelessWidget {
  const _SearchProp({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.94),
      child: Container(
        width: 250.w,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: context.colors.borderSelected),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 17.sp,
              color: context.colors.iconSecondary,
            ),
            SizedBox(width: 10.w),
            Text(
              context.l10n.onbSearchExample,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(width: 2.w),
            Container(width: 1.5, height: 15.sp, color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}

/// The last stage shows a card number being *substituted*, not a price list.
///
/// This used to render [PremiumFeature.all] — four paid features and "and 2
/// more" — which asked somebody to evaluate a subscription to a product they
/// had not used yet, as the final thing before the button that opens it. It
/// was also stale in a way nothing caught: its copy promised rules that file
/// screenshots for you, and filing rules were deleted in v13.
///
/// What replaced it is the one capability neither Google Photos nor Apple
/// Photos will ever ship. Both already read and index every screenshot for
/// free, so "find your screenshots" is a commodity the phone gives away;
/// finding the private detail in one and covering it before it is sent is
/// not. Showing it beats describing it — the number, then the number gone.
///
/// **This drew a substitution until it was caught, and the copy did too.**
/// It showed one card number becoming a second, ordinary-looking one, which
/// is a feature `RedactionService` deleted on purpose: a block says one thing
/// and the user can check it in the preview, while an invented stand-in asks
/// them to believe the app put the right value in the right place. The slide
/// went on selling it for months after the code stopped doing it, and an
/// onboarding that promises what the product will not deliver is worse than
/// one that undersells.
///
/// So the mark here is the real one — [_cover] is the colour and radius
/// `RedactionService._paintCover` paints. If that changes, this changes.
class _SafeShareProp extends StatelessWidget {
  const _SafeShareProp({super.key});

  /// A Visa test prefix, belonging to nobody. It is shown twice — once as the
  /// screenshot has it, once with the block over it — so the second row is
  /// sized by the very digits it covers rather than by a guess.
  static const String _number = '4539 1488 0343 6467';

  /// The colour and corner [RedactionService] actually paints, so the promise
  /// on the first screen and the export the user gets are the same mark.
  static const Color _cover = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.9),
      child: Container(
        width: 268.w,
        padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 13.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The screenshot as it arrived.
            Text(
              _number,
              style: context.text.monoBody.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 7.h),
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 15.sp,
                  color: context.colors.secondary,
                ),
                SizedBox(width: 9.w),
                // The same digits with the block over them, drawn as a stack
                // so the mark is exactly as wide as what it hides. A fixed
                // width would drift the moment the type scale moved, and a
                // cover that is narrower than its number is the one mistake
                // this screen must never illustrate.
                Stack(
                  children: [
                    Text(
                      _number,
                      style: context.text.monoBody.copyWith(
                        color: Colors.transparent,
                      ),
                    ),
                    Positioned.fill(
                      left: -3,
                      right: -3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _cover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
