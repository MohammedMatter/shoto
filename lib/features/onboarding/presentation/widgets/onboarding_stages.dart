import 'package:flutter/widgets.dart';
import 'package:shoto/features/onboarding/presentation/widgets/shot_card.dart';

/// Where one card sits, and how it looks, in one stage.
///
/// Everything here is relative: [x] and [y] are `Alignment` coordinates, so a
/// pose means the same thing on a small phone and a tablet. Nothing in the
/// onboarding is positioned in pixels.
@immutable
class CardPose {
  final double x;
  final double y;
  final double scale;

  /// Rotation in turns, the same unit `RotationTransition` uses.
  final double turns;

  final double opacity;
  final ShotMark mark;

  const CardPose({
    required this.x,
    required this.y,
    this.scale = 1,
    this.turns = 0,
    this.opacity = 1,
    this.mark = ShotMark.none,
  });

  /// Interpolation is what makes the whole idea work: a stage is not a new
  /// screen, it is the **same cards** told to stand somewhere else.
  static CardPose lerp(CardPose a, CardPose b, double t) => CardPose(
    x: a.x + (b.x - a.x) * t,
    y: a.y + (b.y - a.y) * t,
    scale: a.scale + (b.scale - a.scale) * t,
    turns: a.turns + (b.turns - a.turns) * t,
    opacity: a.opacity + (b.opacity - a.opacity) * t,
    // A mark is a state, not a quantity — it switches at the midpoint rather
    // than trying to be half-applied.
    mark: t < 0.5 ? a.mark : b.mark,
  );
}

/// What the stage shows *besides* the cards.
enum StageProp { none, folder, search, premium }

/// One step of the introduction.
@immutable
class OnboardingStage {
  final String Function(BuildContext) title;
  final String Function(BuildContext) body;

  /// Nine poses, always — one per card. A card that is not part of a stage is
  /// given `opacity: 0` and a pose off to the side, so it *leaves* rather than
  /// disappearing. Nothing in this sequence is ever built or destroyed.
  final List<CardPose> poses;

  final StageProp prop;

  const OnboardingStage({
    required this.title,
    required this.body,
    required this.poses,
    this.prop = StageProp.none,
  });

  /// How many cards the whole sequence carries.
  ///
  /// Nine is enough to read as "a pile" and few enough that every one of them
  /// can be given somewhere to be in every stage — which is the constraint
  /// that keeps the sequence honest. If a card cannot be placed meaningfully
  /// in a stage, the stage is wrong.
  static const int cardCount = 9;
}
