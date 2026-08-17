import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_event.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';
import 'package:shoto/features/auth/presentation/widgets/auth_backdrop.dart';
import 'package:shoto/features/auth/presentation/widgets/auth_mark.dart';
import 'package:shoto/features/auth/presentation/widgets/social_sign_in_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state is AuthSuccessState) {
              context.goNamed(AppRouter.homePage);
            } else if (state is AuthErrorState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message.resolve(context)),
                    backgroundColor: context.colors.error,
                  ),
                );
            }
          },
          builder: (BuildContext context, AuthState state) => AuthBody(
            loading: state is AuthLoadingState ? state.method : null,
            onGoogle: () =>
                context.read<AuthBloc>().add(SignInWithGoogleEvent()),
            onApple: () => context.read<AuthBloc>().add(SignInWithAppleEvent()),
          ),
        ),
      ),
    );
  }
}

/// The sign-in screen, with nothing in it that needs a bloc.
///
/// Split out so it can be rendered — and *looked at* — from a golden with no
/// service locator, the same way the subscription card is. This is the first
/// screen anybody sees, and the only honest review of a first impression is a
/// picture of it.
///
/// ## What this screen is for, which is not "log in"
///
/// A person landing here has just installed a screenshot app and is being asked
/// for an account before they have seen a single screenshot. So the page
/// answers, in this order: *what is this* (the mark, filing something, before a
/// word is read), *why an account* (one line), *how* (two buttons), *what am I
/// agreeing to* (one line, small, last).
///
/// ## Why it looks like this
///
/// Four things changed, and each of them replaced something that was correct
/// and said nothing.
///
/// **It is set to the start edge, not centred.** A centred column of logo,
/// title, sentence and two buttons is the default arrangement of every sign-in
/// screen ever generated, and it is default for a reason — it is what you get
/// when no decision is taken about where the eye should start. Ranging
/// everything left gives the page a spine: the mark, the first word of the
/// headline, the first word of the sentence under it and the leading edge of
/// both buttons all sit on one line, and the ragged right that produces is what
/// makes a screen read as typeset rather than as laid out.
///
/// **The mark files itself.** See `AuthMark` — the app's own gesture, played
/// once, saying what the product does before the copy gets a chance to.
///
/// **The two buttons stopped being the same drawing twice.** See
/// [SocialSignInButton]. They are still equal in size and order, which is both
/// Apple's rule and the honest position — providers are not a hierarchy — but
/// one is a card and one is a slab, and the page has a black shape on it now.
///
/// **The privacy note is gone.** It was a bordered box with a lock in it,
/// promising that screenshots stay on the device, sat directly above the
/// buttons. Every word of it was true and it was the wrong screen for it: it
/// answered a worry nobody has yet — you cannot fear for pictures an app has
/// not asked to see — and in doing so it *introduced* the idea that there was
/// something to worry about, one line above the button meant to be pressed. The
/// promise belongs where the permission is actually requested, which is where
/// the app asks to read the gallery.
///
/// ## The entrance
///
/// One controller, [_entrance] long, drives everything: the cards on their own
/// linear interval, then the headline, the sentence, the actions and the legal
/// line each rising [_Rise._travel] pixels as they fade, staggered by about
/// eighty milliseconds. Two clocks on one screen drift; this one cannot.
///
/// It runs **once, on the first build of the screen a person will ever see**,
/// which is the only kind of choreography `app_motion.dart` permits — the rule
/// there is that motion is a tax on anything done daily and a gift on something
/// that happens once, and signing in happens once per install. Reduced motion
/// jumps the controller to its end rather than skipping any of it: everything
/// is still shown, it is simply already there.
class AuthBody extends StatefulWidget {
  /// Which provider is mid-flight, or null. Drives the spinner inside that one
  /// button rather than a screen-wide overlay: the rest of the page stays
  /// readable while a system sheet is up in front of it.
  final AuthMethod? loading;

  final VoidCallback onGoogle;
  final VoidCallback onApple;

  /// Whether to offer Apple. Overridable only so a golden can render the
  /// two-button layout on a machine that is not a Mac.
  @visibleForTesting
  final bool? showApple;

  const AuthBody({
    super.key,
    required this.loading,
    required this.onGoogle,
    required this.onApple,
    this.showApple,
  });

  @override
  State<AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<AuthBody>
    with SingleTickerProviderStateMixin {
  /// The whole arrival, from the first card leaving the top of the frame to the
  /// legal line settling.
  ///
  /// Longer than anything in `app_motion.dart` allows for an interaction, and
  /// deliberately: nothing here is a response to a tap. The user has just
  /// opened the app and is not waiting on this — the constraint that matters is
  /// that the buttons are legible and pressable long before it ends, and the
  /// last of them is fully in at 650ms.
  static const Duration _entrance = Duration(milliseconds: 760);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _entrance,
  );

  /// The cards, on a **linear** interval. `ShotoBrandMarkPainter` eases each of
  /// the three on its own clock; a curve applied here would bunch the staggers
  /// together at whichever end of it is steepest. 0.58 of 760ms is the same
  /// ~440ms the mark is choreographed for everywhere else it plays.
  late final Animation<double> _cards = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.58),
  );

  late final Animation<double> _headline = _step(0.24, 0.66);
  late final Animation<double> _why = _step(0.32, 0.74);
  late final Animation<double> _actions = _step(0.42, 0.86);
  late final Animation<double> _legal = _step(0.50, 0.94);

  /// One block's share of the entrance. The overlaps are wide on purpose —
  /// blocks that queue read as a list being built, blocks that overlap read as
  /// one page arriving.
  Animation<double> _step(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: AppMotion.standard),
  );

  bool _started = false;

  bool get _apple =>
      widget.showApple ?? (!kIsWeb && (Platform.isIOS || Platform.isMacOS));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: the reduced-motion preference is read from the media
    // query, which is not available until dependencies are resolved.
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AuthBackdrop(),
        SafeArea(
          // Scrollable rather than a column of spacers. The old layout used
          // `Spacer(flex: 3)` and `Spacer(flex: 4)`, which is fine at 690pt and
          // overflows the moment the screen is short or the system text is
          // large — on a small phone at 130% type this is two buttons, a
          // paragraph and a legal line with nowhere to go.
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // **[IntrinsicHeight] is what makes the [Spacer] below
                    // legal.** A scroll view hands its child an unbounded
                    // height, and a flexible child of an unbounded column has
                    // nothing to be a fraction *of* — Flutter throws rather
                    // than guessing. This measures the content once so the
                    // column knows how tall it wants to be, and the minHeight
                    // above then stretches it to fill a tall screen. The pair
                    // is what gives both behaviours from one layout: buttons
                    // pinned to the bottom when there is room, an ordinary
                    // scroll when there is not.
                    child: IntrinsicHeight(
                      child: Padding(
                        // Wider than the 24 it was. The column is ranged left
                        // now, so the margin is not just clearance — it is the
                        // only thing setting the measure of the type, and a
                        // headline that starts eight points further in reads as
                        // placed rather than as fitted.
                        padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 28.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 24.h),
                            // **Two spacers, 3 above and 2 below**, rather than
                            // a fixed inset at the top. Pinned high with
                            // everything else at the bottom, the screen had a
                            // third of its height as a hole in the middle and
                            // read as two unrelated groups. Splitting the free
                            // space either side of the hero turns that
                            // emptiness into margin instead of a gap.
                            //
                            // The larger share goes **above**, which is the
                            // opposite of where it was and is what the removal
                            // of the privacy note paid for: with three fewer
                            // lines in the lower group the old ratio left the
                            // hero floating and a canyon under it. Weighted
                            // this way the mark lands at about two fifths down
                            // — where the eye goes first — and what is left
                            // over the buttons reads as the page pausing before
                            // it asks for something. Both collapse to nothing
                            // on a screen too short to afford them, which is
                            // also what gives the cards room to fly in from
                            // above.
                            const Spacer(flex: 3),
                            AuthMark(progress: _cards),
                            SizedBox(height: 26.h),
                            _Rise(
                              animation: _headline,
                              child: Text(
                                context.l10n.authWelcome,
                                style: context.text.displayLarge,
                                textAlign: TextAlign.start,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _Rise(
                              animation: _why,
                              child: Text(
                                context.l10n.authWhy,
                                textAlign: TextAlign.start,
                                style: context.text.bodyLarge.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(height: 28.h),
                            const Spacer(flex: 2),
                            _Rise(
                              animation: _actions,
                              child: Column(
                                children: <Widget>[
                                  SocialSignInButton(
                                    brand: SignInBrand.google,
                                    // The slab goes to the last provider on the
                                    // screen — see [SocialSignInButton]. On
                                    // Android there is no second one, so this is
                                    // it; on Apple's platforms this is the card
                                    // and the one below is the slab.
                                    filled: !_apple,
                                    label: context.l10n.authGoogle,
                                    isLoading:
                                        widget.loading == AuthMethod.google,
                                    onPressed: widget.onGoogle,
                                  ),
                                  if (_apple) ...<Widget>[
                                    SizedBox(height: 12.h),
                                    SocialSignInButton(
                                      brand: SignInBrand.apple,
                                      filled: true,
                                      label: context.l10n.authApple,
                                      isLoading:
                                          widget.loading == AuthMethod.apple,
                                      onPressed: widget.onApple,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            _Rise(
                              animation: _legal,
                              child: Text(
                                context.l10n.authLegal,
                                textAlign: TextAlign.start,
                                // `caption` is already secondary; the only
                                // override is the extra leading, which two
                                // lines of 11.5sp legal text need to stay
                                // readable rather than compact.
                                style: context.text.caption.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

/// One block of the page arriving: a fade, and a short lift.
///
/// **A fixed distance rather than a [SlideTransition]'s fraction of the
/// block's own height.** The four things that arrive here are a headline, a
/// sentence, a hundred-and-twenty-point stack of buttons and a caption; a
/// fractional offset would move each of them a different distance, so the
/// buttons would travel three times as far as the caption and the page would
/// arrive at four speeds. Fourteen points is the same lift for all of them.
///
/// The lift is small on purpose. Anything past about twenty points stops
/// reading as the page settling and starts reading as content being flung in,
/// which is the tell of a template.
class _Rise extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _Rise({required this.animation, required this.child});

  static const double _travel = 14;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      // Built once and handed through: the subtree does not depend on the
      // animation's value, only its position and opacity do.
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _travel),
            child: child,
          ),
        );
      },
    );
  }
}
