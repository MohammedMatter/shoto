import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_stages.dart';
import 'package:shoto/features/onboarding/presentation/widgets/shot_card.dart';
import 'package:shoto/features/onboarding/presentation/widgets/stage_canvas.dart';

/// The introduction, built around one idea: **a pile becomes a library.**
///
/// The old version was five stock photographs drifting behind a frosted panel
/// while a paragraph faded in and out on top. It had two problems worth
/// stating, because they are the reasons this exists.
///
/// It described the app instead of showing it — and what it described was no
/// longer true. It promised SHOTO "automatically finds every screenshot you
/// take", which was reversed three sessions ago: the library is opt-in now,
/// and the first thing a new user was told was the one thing the app
/// deliberately does not do.
///
/// So the sequence is built out of the app's own material. Nine drawn
/// screenshots start as a pile — angled, overlapping, the way a thousand
/// screenshots actually feel — and **the same nine cards** are then dealt
/// with in front of you: most of them leave, because you choose what SHOTO
/// keeps; the survivors square up and take the clipped corner, because they
/// have been filed; one lights up a line of its own text, because that is
/// what searching inside a picture looks like; one covers its card number,
/// because that is what Safe Share does. Nothing is illustrated. Every claim
/// is performed on the object it is about.
///
/// Nothing here is loaded from anywhere. The old screen had a data source, a
/// repository, a use case and a bloc behind a JSON file of marketing copy —
/// four layers to fetch five sentences that have to be translated anyway. The
/// copy is in the ARB files with the rest of the app's language, and the Pro
/// stage reads [PremiumFeature.all], the list the paywall itself renders
/// from, so the introduction cannot promise a feature set that no longer
/// matches the product.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.sheet,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standard,
  );

  int _index = 0;

  /// Where the cards are coming *from*. Held rather than derived, because a
  /// stage can be left before it has finished arriving — tap Next twice
  /// quickly and the second move must start from wherever the cards actually
  /// are, not from where the previous stage said they should be.
  late List<CardPose> _from = _stages(context).first.poses;

  @override
  void initState() {
    super.initState();
    // The first stage animates in from a tighter, deader version of itself:
    // the pile lands on the screen rather than being there already.
    _from = _entryPoses();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final double t = _progress.value;
    return [
      for (int i = 0; i < OnboardingStage.cardCount; i++)
        CardPose.lerp(_from[i], target[i], t),
    ];
  }

  void _finish() {
    // Written on the way out rather than on the way in: somebody who opened
    // the app, saw the intro and closed it has not been introduced to
    // anything.
    sl<AppPreferences>().markOnboardingSeen();
    // Recorded here rather than on the last stage being *shown*: reaching the
    // final card and closing the app is not finishing the introduction, and
    // the gap between those two numbers is the thing worth being able to see.
    sl<FunnelLog>().record(FunnelStep.onboardingCompleted);
    // On to signing in. The introduction explains what the app is; the
    // account is the step after that, and the app itself is the step after
    // *that* — see `docs/decisions/accounts.md` for the history of this
    // sequence, which has been both ways round.
    context.goNamed(AppRouter.authPage);
  }

  @override
  Widget build(BuildContext context) {
    final List<OnboardingStage> stages = _stages(context);
    final OnboardingStage stage = stages[_index];
    final bool isLast = _index == stages.length - 1;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 12.w, 0),
              child: Row(
                children: [
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

            // The whole sequence is swipeable, because a row of segments at
            // the top of a screen promises it is. Velocity rather than
            // distance: a flick should be enough, and there is no scrollable
            // here for the gesture to fight over.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final double v = details.primaryVelocity ?? 0;
                  if (v.abs() < 240) return;
                  final bool forward = rtl ? v > 0 : v < 0;
                  _goTo(forward ? _index + 1 : _index - 1);
                },
                // A bounded stage, centred in whatever space is left, rather
                // than a canvas that stretches with the screen. Poses are
                // fractions of this box, so the composition — how close the
                // folder sits under the stack, how far the pile spills past
                // the edges — is the same on a small phone and a tall one.
                // Stretching it left the props marooned at the bottom of a
                // tall screen with a hole in the middle.
                child: Center(
                  child: SizedBox(
                    height: 372.h,
                    width: double.infinity,
                    child: StageCanvas(
                      from: _from,
                      to: stage.poses,
                      prop: stage.prop,
                      progress: _progress,
                    ),
                  ),
                ),
              ),
            ),

            _Copy(
              // Keyed by index so the switcher knows this is different text
              // rather than the same text with different characters.
              key: ValueKey<int>(_index),
              title: stage.title(context),
              body: stage.body(context),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 14.h),
              child: Column(
                children: [
                  PrimaryButton(
                    label: isLast
                        ? context.l10n.onboardingCta
                        : context.l10n.onbNext,
                    onPressed: isLast ? _finish : () => _goTo(_index + 1),
                  ),
                  SizedBox(height: 10.h),
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
      ),
    );
  }
}

/// The headline and the line under it, swapped as one block.
class _Copy extends StatelessWidget {
  final String title;
  final String body;

  const _Copy({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.normal),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          // Rises a little as it arrives. Small on purpose: the cards are
          // doing the moving on this screen, and text that travels as far as
          // they do competes with them.
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomCenter,
        children: [...previous, ?current],
      ),
      child: Padding(
        key: key,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.headlineLarge),
            SizedBox(height: 8.h),
            Text(
              body,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the pile comes from on first paint: the same arrangement, pulled in
/// tighter and flat. It expands into the pile rather than appearing as one.
List<CardPose> _entryPoses() => [
  for (final CardPose pose in _pile)
    CardPose(
      x: pose.x * 0.35,
      y: pose.y * 0.35,
      scale: pose.scale * 0.9,
      turns: 0,
      opacity: 0,
    ),
];

/// **Stage one — the pile.** Angled, overlapping, spilling past the edges.
/// This is the only stage that is allowed to look untidy, and it has to: it
/// is the problem the rest of the sequence answers.
const List<CardPose> _pile = [
  CardPose(x: -0.72, y: -0.52, turns: -0.045, scale: 0.92),
  CardPose(x: -0.15, y: -0.66, turns: 0.03),
  CardPose(x: 0.62, y: -0.48, turns: 0.06, scale: 0.95),
  CardPose(x: -0.82, y: 0.12, turns: 0.025, scale: 0.88),
  CardPose(x: -0.05, y: -0.02, turns: -0.015, scale: 1.04),
  CardPose(x: 0.78, y: 0.06, turns: -0.05, scale: 0.9),
  CardPose(x: -0.5, y: 0.66, turns: 0.05, scale: 0.94),
  CardPose(x: 0.2, y: 0.72, turns: -0.03, scale: 0.9),
  CardPose(x: 0.86, y: 0.68, turns: 0.04, scale: 0.86),
];

/// **Stage two — you choose.** Six cards leave the way they came in; three
/// stay, straighten and line up. The rule the whole app is built on, shown
/// as an act of subtraction.
const List<CardPose> _chosen = [
  CardPose(x: -1.9, y: -0.9, turns: -0.12, scale: 0.8, opacity: 0),
  CardPose(x: -0.62, y: -0.06, turns: 0, scale: 0.96),
  CardPose(x: 1.9, y: -0.9, turns: 0.12, scale: 0.8, opacity: 0),
  CardPose(x: -1.9, y: 0.3, turns: -0.1, scale: 0.8, opacity: 0),
  CardPose(x: 0, y: -0.06, turns: 0, scale: 0.96),
  CardPose(x: 1.9, y: 0.3, turns: 0.1, scale: 0.8, opacity: 0),
  CardPose(x: -1.9, y: 1.2, turns: -0.08, scale: 0.8, opacity: 0),
  CardPose(x: 0.62, y: -0.06, turns: 0, scale: 0.96),
  CardPose(x: 1.9, y: 1.2, turns: 0.08, scale: 0.8, opacity: 0),
];

/// **Stage three — filed.** The three fan into a small stack above a folder,
/// and take the clipped corner: the app's one signature shape, appearing at
/// the exact moment it means something.
const List<CardPose> _filed = [
  CardPose(x: -1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -0.3, y: -0.3, turns: -0.03, scale: 0.9, mark: ShotMark.filed),
  CardPose(x: 1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: 0, y: -0.34, turns: 0, scale: 0.94, mark: ShotMark.filed),
  CardPose(x: 1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 1.2, opacity: 0, scale: 0.8),
  CardPose(x: 0.3, y: -0.3, turns: 0.03, scale: 0.9, mark: ShotMark.filed),
  CardPose(x: 1.9, y: 1.2, opacity: 0, scale: 0.8),
];

/// **Stage four — found.** One card comes forward with a line of its text lit
/// up; the other two step back and dim. This is what a search hit *is*: not a
/// list of file names, a word found inside a picture.
const List<CardPose> _found = [
  CardPose(x: -1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -0.55, y: -0.34, turns: -0.04, scale: 0.78, opacity: 0.35),
  CardPose(x: 1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: 0, y: -0.36, scale: 1.12, mark: ShotMark.found),
  CardPose(x: 1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 1.2, opacity: 0, scale: 0.8),
  CardPose(x: 0.55, y: -0.34, turns: 0.04, scale: 0.78, opacity: 0.35),
  CardPose(x: 1.9, y: 1.2, opacity: 0, scale: 0.8),
];

/// **Stage five — Pro.** The cards retreat to a tidy fan at the top and hand
/// the screen to the paid list. One of them is covering a card number, which
/// is the single most concrete thing SHOTO does and the last thing seen
/// before the button.
const List<CardPose> _pro = [
  CardPose(x: -1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -0.48, y: -0.5, turns: -0.05, scale: 0.72, opacity: 0.9),
  CardPose(x: 1.9, y: -0.9, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: 0, y: -0.58, scale: 0.82, mark: ShotMark.covered),
  CardPose(x: 1.9, y: 0.3, opacity: 0, scale: 0.8),
  CardPose(x: -1.9, y: 1.2, opacity: 0, scale: 0.8),
  CardPose(x: 0.48, y: -0.5, turns: 0.05, scale: 0.72, opacity: 0.9),
  CardPose(x: 1.9, y: 1.2, opacity: 0, scale: 0.8),
];

List<OnboardingStage> _stages(BuildContext context) => [
  OnboardingStage(
    title: (context) => context.l10n.onbPileTitle,
    body: (context) => context.l10n.onbPileBody,
    poses: _pile,
  ),
  OnboardingStage(
    title: (context) => context.l10n.onbChooseTitle,
    body: (context) => context.l10n.onbChooseBody,
    poses: _chosen,
  ),
  OnboardingStage(
    title: (context) => context.l10n.onbFileTitle,
    body: (context) => context.l10n.onbFileBody,
    poses: _filed,
    prop: StageProp.folder,
  ),
  OnboardingStage(
    title: (context) => context.l10n.onbFindTitle,
    body: (context) => context.l10n.onbFindBody,
    poses: _found,
    prop: StageProp.search,
  ),
  // Last, and no longer a price list.
  //
  // This stage used to pitch the subscription — six paid features shown to
  // somebody who had not yet saved a single screenshot, as the final thing
  // before the button that lets them start. Its copy also still promised
  // rules that file screenshots for you, three releases after filing rules
  // were deleted.
  //
  // It now ends on the one thing the phone's own gallery will never do.
  OnboardingStage(
    title: (context) => context.l10n.onbSafeShareTitle,
    body: (context) => context.l10n.onbSafeShareBody,
    poses: _pro,
    prop: StageProp.safeShare,
  ),
];
