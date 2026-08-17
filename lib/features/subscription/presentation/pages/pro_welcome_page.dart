import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/pro_badge.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// Shown once, the moment a subscription actually completes.
///
/// **Why this screen is allowed to exist at all.** Every other rule in this
/// app's motion file is about restraint, and it is right: almost everything
/// here is something a person does dozens of times a day, where choreography
/// becomes a tax. This is the opposite case in every dimension — it happens at
/// most once per account, the user has just paid money, and the one thing the
/// app owes them in return is the feeling that something changed. A purchase
/// that dismisses a sheet and returns you to a settings row you were already
/// looking at is the app taking the money without acknowledging it.
///
/// **Why the brand mark.** The mark is a tray with three screenshots filing
/// into it, and that animation used to live on a Flutter splash screen that
/// existed only to imitate the native launch window. Removing that screen left
/// the app's single most characteristic piece of motion with nowhere to play —
/// so it plays here instead, which is a better home than a launch screen was:
/// the gesture that means "Shoto is filing this for you" now belongs to the
/// moment somebody bought the thing that does the filing.
class ProWelcomePage extends StatefulWidget {
  const ProWelcomePage({super.key});

  @override
  State<ProWelcomePage> createState() => _ProWelcomePageState();
}

class _ProWelcomePageState extends State<ProWelcomePage>
    with SingleTickerProviderStateMixin {
  /// The mark's size, in logical pixels — flat rather than `.w`, so the
  /// choreography inside the painter keeps its proportions on every phone.
  static const double _markSize = 108;

  /// How long the three cards take to file themselves. The same 440ms the
  /// splash used: each card runs for 70% of it and they start 15% apart, so
  /// one card's travel is ~310ms and the three overlap rather than queue.
  static const Duration _file = Duration(milliseconds: 440);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _file,
  );

  /// Driven **uncurved** on purpose: [ShotoBrandMarkPainter] eases each card on
  /// its own clock, and a curve applied to the parent would bunch the three
  /// staggers together at whichever end of it is steepest.
  Animation<double> get _cards => _controller;

  late final Animation<double> _textIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: AppMotion.standard),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AppMotion.reduced(context)) {
      // Reduced motion drops the movement, not the screen. Everything is still
      // shown, it is simply already there.
      _controller.value = 1;
    } else {
      _controller.forward();
    }

    // "Something committed: saved, filed, deleted, unlocked." This is the most
    // committed thing that happens in the app.
    Haptics.confirm();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              const Spacer(flex: 3),
              SizedBox(
                width: _markSize,
                height: _markSize,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _cards,
                    builder: (context, _) => CustomPaint(
                      painter: ShotoBrandMarkPainter(
                        markExtent: _markSize,
                        progress: _cards.value,
                      ),
                      isComplex: true,
                      willChange: true,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              // Everything below arrives together, once the last card has
              // nearly landed. It was not on screen a moment ago, so unlike the
              // tray it is allowed to enter.
              FadeTransition(
                opacity: _textIn,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(_textIn),
                  child: Column(
                    children: [
                      const ProBadge(),
                      SizedBox(height: 14.h),
                      Text(
                        context.l10n.proWelcomeTitle,
                        style: context.text.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        context.l10n.proWelcomeBody,
                        style: context.text.bodyLarge.copyWith(
                          color: context.colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 4),
              // The button is **not** part of the fade. Nothing here is a
              // countdown or a modal — somebody who has already read the two
              // words and wants their app back must be able to leave on the
              // first frame, including anyone who cannot see the animation at
              // all.
              PrimaryButton(
                label: context.l10n.proWelcomeAction,
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the welcome screen and makes sure the rest of the app already agrees
/// that this account is on Pro before it is dismissed.
///
/// The refresh is awaited **first** on purpose. Popping back to a settings page
/// still showing the upgrade card — and to a Home whose wordmark has no badge
/// — would undo the whole point of the screen in the frame after it closed.
Future<void> showProWelcome(BuildContext context) async {
  await sl<ProStatus>().refresh();
  if (!context.mounted) return;

  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: AppMotion.duration(context, AppMotion.sheet),
      reverseTransitionDuration: AppMotion.duration(context, AppMotion.normal),
      pageBuilder: (_, _, _) => const ProWelcomePage(),
      // A plain fade. The screen's own content is doing the arriving; sliding
      // the whole page in underneath it would be two entrances at once.
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
