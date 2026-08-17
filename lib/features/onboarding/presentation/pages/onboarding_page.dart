import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_chips.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_opening.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_stages.dart';
import 'package:shoto/features/onboarding/presentation/widgets/shot_card.dart';
import 'package:shoto/features/onboarding/presentation/widgets/stage_canvas.dart';

/// The introduction, built around one idea: **a pile becomes a library.**
///
/// Two movements. [OnboardingOpening] is five seconds of screenshots falling
/// into the mark, with nothing to read and nothing to press but Skip — the
/// app says what it is before it asks for anything. Then five stages, one per
/// thing the product actually does, in the order a person meets them: how a
/// screenshot gets in, where it lands, how it is found again, what happens
/// when it is sent on, and who is allowed to move any of it.
///
/// ## Why it is built out of the app's own material
///
/// Nothing here is a photograph and nothing is an asset. Nine drawn cards
/// carry the whole sequence — the same nine widgets are alive from the first
/// stage to the last, told to stand somewhere else each time. Cards spill,
/// then square up and take the clipped corner because they have been filed;
/// one lights a line of its own text because that is what searching inside a
/// picture looks like; one covers its card number because that is what Safe
/// Share does. The props beside them — the share sheet, the folder row, the
/// search field — are drawn with the app's own tokens, so what the
/// introduction promises and what the app looks like cannot drift apart.
///
/// The alternative is what was here two versions ago: five stock photographs
/// drifting behind a frosted panel while a paragraph faded in and out. It
/// described the app instead of showing it, and what it described had stopped
/// being true — it promised Shoto "automatically finds every screenshot you
/// take", which had been reversed three sessions earlier.
///
/// ## The layout, and why the copy sits at the bottom
///
/// Progress at the top, a stage that takes whatever height is left, then the
/// headline, one sentence, the chips and the button — in that order, hard
/// against the bottom of the screen. The eye starts at a moving picture and
/// finishes on a control, every time, on every stage. Nothing is centred: a
/// centred column of picture-title-sentence-button is what a page looks like
/// when no decision has been taken about where reading begins.
///
/// ## Cost
///
/// Every stage loses a share of the people who started, so the question for
/// anything added here is not "is this true" — all of it is — but "will they
/// still be here for the one after it". Five is the ceiling. A sixth stage
/// would have to displace one of these, and each of the five is the only place
/// its capability is explained before the user meets it cold.
class OnboardingPage extends StatefulWidget {
  /// Starts at the first stage rather than at the opening.
  ///
  /// Overridable only so a golden can render the stages. The control that ends
  /// the opening is a [PrimaryButton], which fires haptics, which reach for
  /// [AppPreferences] through the service locator — and a widget test has no
  /// locator. It is the same reason the progress segments carry keys: see
  /// `onboarding_progress.dart`.
  @visibleForTesting
  final bool startAtStages;

  const OnboardingPage({super.key, this.startAtStages = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  /// The stage change: cards travelling, and the copy under them being
  /// replaced. Longer than [AppMotion.sheet] because the cards are crossing
  /// most of the screen and the chips are dealt after the sentence lands.
  static const Duration _change = Duration(milliseconds: 620);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _change,
  );

  /// The cards get the whole window on the app's standard curve. The copy
  /// blocks take intervals of the same controller — see [_CopyBlock] — so the
  /// picture and the words it belongs to can never fall out of step.
  late final Animation<double> _cards = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standard,
  );

  /// The stage's height at full size, and the number the scale below is a
  /// fraction of.
  double get _stageHeight => 330.h;

  late bool _opening = !widget.startAtStages;
  int _index = 0;

  /// Where the cards are coming *from*. Held rather than derived, because a
  /// stage can be left before it has finished arriving — tap Next twice
  /// quickly and the second move must start from wherever the cards actually
  /// are, not from where the previous stage said they should be.
  late List<CardPose> _from = _entryPoses();

  @override
  void initState() {
    super.initState();
    // **Built here even though the stages may never be reached.** A
    // `late final` field is created on first read, and for anybody who skips
    // the opening the first read is `dispose()` — which constructs an
    // `AnimationController` while the element is being torn down, and throws
    // on the ticker's ancestor lookup. Touching it now is the whole fix.
    _controller.value = 0;
    if (!_opening) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The opening is over: the stages take the screen.
  void _begin() {
    setState(() => _opening = false);
    _controller
      ..value = 0
      ..forward();
  }

  void _goTo(int next) {
    final List<OnboardingStage> stages = _stages(context);
    if (next < 0 || next >= stages.length || next == _index) return;

    final List<CardPose> current = _resolvedPoses();
    setState(() {
      _from = current;
      _index = next;
    });
    _controller
      ..value = 0
      ..forward();
  }

  /// Where every card is at this exact moment, mid-flight included.
  List<CardPose> _resolvedPoses() {
    final List<CardPose> target = _stages(context)[_index].poses;
    final double t = _cards.value;
    return <CardPose>[
      for (int i = 0; i < OnboardingStage.cardCount; i++)
        CardPose.lerp(_from[i], target[i], t),
    ];
  }

  void _finish() {
    final AppPreferences preferences = sl<AppPreferences>();

    // **Only the first time counts.** Both of these belong to somebody being
    // introduced to the app, and neither is true of the person who opened this
    // again from Settings months later — marking it seen is already done, and
    // recording a completion would quietly inflate the one number that says
    // how many new users got through the introduction on their way in.
    if (!preferences.hasSeenOnboarding) {
      // Written on the way out rather than on the way in: somebody who opened
      // the app, saw the intro and closed it has not been introduced to
      // anything.
      preferences.markOnboardingSeen();
      // Recorded here rather than on the last stage being *shown*: reaching
      // the final card and closing the app is not finishing the introduction,
      // and the gap between those two numbers is the thing worth being able to
      // see.
      sl<FunnelLog>().record(FunnelStep.onboardingCompleted);
    }

    // Replayed from Settings there is nothing to advance to — the person is
    // already signed in and already using the app, and sending them to the
    // sign-in screen would be a bug wearing a route name. Popping is also the
    // only correct answer for the back gesture, so both use this.
    if (context.canPop()) {
      context.pop();
    } else {
      // On to signing in. The introduction explains what the app is; the
      // account is the step after that, and the app itself is the step after
      // *that* — see `docs/decisions/accounts.md` for the history of this
      // sequence, which has been both ways round.
      context.goNamed(AppRouter.authPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.sheet),
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.standard,
        child: _opening
            ? OnboardingOpening(
                key: const ValueKey<String>('opening'),
                onStart: _begin,
                onSkip: _finish,
              )
            : _stageView(context),
      ),
    );
  }

  Widget _stageView(BuildContext context) {
    final List<OnboardingStage> stages = _stages(context);
    final OnboardingStage stage = stages[_index];
    final bool isLast = _index == stages.length - 1;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return SafeArea(
      key: const ValueKey<String>('stages'),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 12.w, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OnboardingProgress(
                    count: stages.length,
                    index: _index,
                    onTap: _goTo,
                  ),
                ),
                SizedBox(width: 12.w),
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    context.l10n.onbSkip,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The whole sequence is swipeable, because a row of segments at the
          // top of a screen promises it is. Velocity rather than distance: a
          // flick should be enough, and there is no scrollable here for the
          // gesture to fight over.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (DragEndDetails details) {
                final double v = details.primaryVelocity ?? 0;
                if (v.abs() < 240) return;
                final bool forward = rtl ? v > 0 : v < 0;
                _goTo(forward ? _index + 1 : _index - 1);
              },
              // Poses are fractions of this box, so the composition — how
              // close the sheet sits under the cards, how far the pile spills
              // past the edges — holds its proportions on a small phone and a
              // tall one. A canvas that stretched with the screen left the
              // props marooned at the bottom with a hole in the middle.
              //
              // **The scale is not decoration, it is the fix for a real
              // squeeze.** Poses are fractions but [ShotCard] is a fixed size,
              // so a box shorter than the design height packs the same cards
              // into less room and the stage turns into a jam — caught on the
              // German golden at 1.3× type on a 1780px screen, where the share
              // sheet ended up in the headline. Scaling the whole stage by how
              // much height it actually got keeps every proportion in the
              // composition and simply makes it smaller, which is what a
              // shorter screen is asking for.
              child: Center(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints room) {
                    final double height = math.min(_stageHeight, room.maxHeight);
                    return SizedBox(
                      height: height,
                      width: double.infinity,
                      child: Transform.scale(
                        // Floored: past a point shrinking the cards stops
                        // helping and starts making them unreadable, and a
                        // little spill past the top of the stage is better than
                        // a stage nobody can make out.
                        scale: (height / _stageHeight).clamp(0.72, 1.0),
                        child: StageCanvas(
                          from: _from,
                          to: stage.poses,
                          prop: stage.prop,
                          progress: _cards,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          _CopyBlock(
            // Keyed by index so the block knows this is different text rather
            // than the same text with different characters.
            key: ValueKey<int>(_index),
            stage: stage,
            controller: _controller,
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 14.h),
            child: Column(
              children: <Widget>[
                PrimaryButton(
                  label: isLast
                      ? context.l10n.onboardingCta
                      : context.l10n.onbNext,
                  onPressed: isLast ? _finish : () => _goTo(_index + 1),
                ),
                SizedBox(height: 10.h),
                // Where the reference design puts a second action, this puts
                // the one promise the app has to keep. It is true on every
                // stage, so it is on every stage — and a person deciding
                // whether to go on reads it four times without being asked to
                // read it once.
                Text(
                  context.l10n.onboardingPromise,
                  textAlign: TextAlign.center,
                  style: context.text.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline, the sentence and the chips — arriving in that order.
///
/// Three intervals of the stage's own controller rather than three
/// animations: the whole block is rebuilt once per frame anyway because the
/// chips move, and a `CurvedAnimation` per row would put three more listeners
/// on a ticker that is already being read.
class _CopyBlock extends StatelessWidget {
  final OnboardingStage stage;
  final Animation<double> controller;

  const _CopyBlock({super.key, required this.stage, required this.controller});

  static const Interval _title = Interval(0.10, 0.62, curve: AppMotion.standard);
  static const Interval _body = Interval(0.20, 0.74, curve: AppMotion.standard);
  static const Interval _chips = Interval(0.32, 1);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final double t = controller.value;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Rise(
                t: _title.transform(t),
                child: Text(
                  stage.title(context),
                  style: context.text.headlineLarge,
                ),
              ),
              SizedBox(height: 8.h),
              _Rise(
                t: _body.transform(t),
                child: Text(
                  stage.body(context),
                  style: context.text.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              if (stage.chips.isNotEmpty) ...<Widget>[
                SizedBox(height: 16.h),
                OnboardingChips(
                  chips: stage.chips,
                  progress: _chips.transform(t),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A fade and a short lift. Small on purpose: the cards are doing the moving
/// on this screen, and text that travels as far as they do competes with them.
class _Rise extends StatelessWidget {
  final double t;
  final Widget child;

  const _Rise({required this.t, required this.child});

  static const double _travel = 12;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - t) * _travel),
        child: child,
      ),
    );
  }
}

/// Where the pile comes from on the first stage: the same arrangement, pulled
/// in tighter and flat. It expands into the pile rather than appearing as one.
List<CardPose> _entryPoses() => <CardPose>[
  for (final CardPose pose in _incoming)
    CardPose(
      x: pose.x * 0.35,
      y: pose.y * 0.35,
      scale: pose.scale * 0.9,
      turns: 0,
      opacity: 0,
    ),
];

/// **Stage one — arriving.** Cards angled and overlapping above the share
/// sheet, one of them already on its way down into it. This is the pile the
/// rest of the sequence answers, caught at the moment one of them is being
/// handed over.
const List<CardPose> _incoming = <CardPose>[
  CardPose(x: -0.78, y: -0.86, turns: -0.045, scale: 0.9),
  CardPose(x: -0.16, y: -0.98, turns: 0.03, scale: 0.95),
  CardPose(x: 0.66, y: -0.82, turns: 0.06, scale: 0.92),
  CardPose(x: -0.88, y: -0.24, turns: 0.025, scale: 0.86),
  CardPose(x: -0.06, y: -0.34, turns: -0.015, scale: 1),
  CardPose(x: 0.82, y: -0.2, turns: -0.05, scale: 0.88),
  CardPose(x: -0.54, y: 0.32, turns: 0.05, scale: 0.84),
  // The one being sent: square, centred, on its way to the sheet below.
  CardPose(x: 0, y: 0.34, turns: 0, scale: 0.78),
  CardPose(x: 0.9, y: 0.36, turns: 0.04, scale: 0.82),
];

/// **Stage two — filed.** Six leave the way they came in; three stay, square
/// up and take the clipped corner. The rule the whole app is built on, shown
/// as an act of subtraction rather than stated as a feature.
const List<CardPose> _filed = <CardPose>[
  CardPose(x: -1.9, y: -0.9, turns: -0.12, scale: 0.8, opacity: 0),
  CardPose(x: -0.62, y: -0.06, scale: 0.92, mark: ShotMark.filed),
  CardPose(x: 1.9, y: -0.9, turns: 0.12, scale: 0.8, opacity: 0),
  CardPose(x: -1.9, y: 0.3, turns: -0.1, scale: 0.8, opacity: 0),
  CardPose(x: 0, y: -0.06, scale: 0.92, mark: ShotMark.filed),
  CardPose(x: 1.9, y: 0.3, turns: 0.1, scale: 0.8, opacity: 0),
  CardPose(x: -1.9, y: 1.2, turns: -0.08, scale: 0.8, opacity: 0),
  CardPose(x: 0.62, y: -0.06, scale: 0.92, mark: ShotMark.filed),
  CardPose(x: 1.9, y: 1.2, turns: 0.08, scale: 0.8, opacity: 0),
];

/// **Stage three — found.** The three that stayed step back except one, which
/// comes forward with a line of its own text lit. The search field underneath
/// holds the word that found it.
const List<CardPose> _found = <CardPose>[
  CardPose(x: -1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -0.66, y: -0.52, turns: -0.04, scale: 0.72, opacity: 0.55),
  CardPose(x: 1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: 0, y: -0.46, scale: 1.05, mark: ShotMark.found),
  CardPose(x: 1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 1.2, opacity: 0, scale: 0.8),
  CardPose(x: 0.66, y: -0.52, turns: 0.04, scale: 0.72, opacity: 0.55),
  CardPose(x: 1.9, y: 1.2, opacity: 0, scale: 0.8),
];

/// **Stage four — Safe Share.** The cards retreat to a tidy fan at the top and
/// hand the screen to the cover itself. One of them is hiding a card number,
/// which is the single most concrete thing Shoto does.
const List<CardPose> _covered = <CardPose>[
  CardPose(x: -1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -0.48, y: -0.62, turns: -0.05, scale: 0.72, opacity: 0.9),
  CardPose(x: 1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: 0, y: -0.68, scale: 0.82, mark: ShotMark.covered),
  CardPose(x: 1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 1.2, opacity: 0, scale: 0.8),
  CardPose(x: 0.48, y: -0.62, turns: 0.05, scale: 0.72, opacity: 0.9),
  CardPose(x: 1.9, y: 1.2, opacity: 0, scale: 0.8),
];

/// **Stage five — yours.** Three filed cards, squared and evenly spaced, with
/// nothing else on the stage. The last thing seen before the button is the
/// library at rest: small, tidy, and nothing in it that was not handed over.
const List<CardPose> _kept = <CardPose>[
  CardPose(x: -1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -0.62, y: -0.06, scale: 0.96, mark: ShotMark.filed),
  CardPose(x: 1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: 0, y: -0.06, scale: 0.96, mark: ShotMark.filed),
  CardPose(x: 1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 1.2, opacity: 0, scale: 0.8),
  CardPose(x: 0.62, y: -0.06, scale: 0.96, mark: ShotMark.filed),
  CardPose(x: 1.9, y: 1.2, opacity: 0, scale: 0.8),
];

/// **Five stages, and the order is the argument.**
///
/// In, filed, found, sent, and who is allowed to move it — a screenshot's
/// whole life through the app, in the order it happens. The privacy stage is
/// last and not first on purpose: "nothing moves without you" is a promise
/// about things, and it only means anything once there are things.
List<OnboardingStage> _stages(BuildContext context) => <OnboardingStage>[
  // Where screenshots come from, which is the one thing a person cannot work
  // out for themselves. The library does not fill itself and the app never
  // opens the gallery — if this stage does not land, nothing after it can.
  OnboardingStage(
    title: (BuildContext context) => context.l10n.onbSaveTitle,
    body: (BuildContext context) => context.l10n.onbSaveBody,
    poses: _incoming,
    prop: StageProp.shareSheet,
    chips: <StageChip>[
      StageChip(
        icon: Icons.apps_rounded,
        label: (BuildContext context) => context.l10n.onbChipAnyApp,
      ),
      StageChip(
        icon: Icons.touch_app_outlined,
        label: (BuildContext context) => context.l10n.onbChipOneTap,
      ),
      StageChip(
        icon: Icons.folder_outlined,
        label: (BuildContext context) => context.l10n.onbChipToFolder,
      ),
    ],
  ),

  OnboardingStage(
    title: (BuildContext context) => context.l10n.onbFileTitle,
    body: (BuildContext context) => context.l10n.onbFileBody,
    poses: _filed,
    prop: StageProp.folders,
    chips: <StageChip>[
      StageChip(
        icon: Icons.create_new_folder_outlined,
        label: (BuildContext context) => context.l10n.onbChipFolders,
      ),
      StageChip(
        icon: Icons.star_outline_rounded,
        label: (BuildContext context) => context.l10n.onbChipFavourites,
      ),
      StageChip(
        icon: Icons.content_copy_outlined,
        label: (BuildContext context) => context.l10n.onbChipDuplicates,
      ),
    ],
  ),

  OnboardingStage(
    title: (BuildContext context) => context.l10n.onbFindTitle,
    body: (BuildContext context) => context.l10n.onbFindBody,
    poses: _found,
    prop: StageProp.search,
    chips: <StageChip>[
      StageChip(
        icon: Icons.text_fields_rounded,
        label: (BuildContext context) => context.l10n.onbChipInsideText,
      ),
      StageChip(
        icon: Icons.cloud_off_outlined,
        label: (BuildContext context) => context.l10n.onbChipOffline,
      ),
    ],
  ),

  // The cover itself, and not a price list. This stage used to pitch the
  // subscription — six paid features shown to somebody who had not yet saved a
  // single screenshot, as the last thing before the button that opens the app.
  OnboardingStage(
    title: (BuildContext context) => context.l10n.onbSendTitle,
    body: (BuildContext context) => context.l10n.onbSendBody,
    poses: _covered,
    prop: StageProp.safeShare,
    chips: <StageChip>[
      StageChip(
        icon: Icons.credit_card_outlined,
        label: (BuildContext context) => context.l10n.onbChipCards,
      ),
      StageChip(
        icon: Icons.password_rounded,
        label: (BuildContext context) => context.l10n.onbChipCodes,
      ),
      StageChip(
        icon: Icons.visibility_outlined,
        label: (BuildContext context) => context.l10n.onbChipPreview,
      ),
    ],
  ),

  OnboardingStage(
    title: (BuildContext context) => context.l10n.onbYoursTitle,
    body: (BuildContext context) => context.l10n.onbYoursBody,
    poses: _kept,
    chips: <StageChip>[
      StageChip(
        icon: Icons.photo_library_outlined,
        label: (BuildContext context) => context.l10n.onbChipGallery,
      ),
      StageChip(
        icon: Icons.smartphone_outlined,
        label: (BuildContext context) => context.l10n.onbChipOnDevice,
      ),
    ],
  ),
];
