import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';

/// One place for how motion feels, so timings don't drift apart screen by
/// screen — inconsistent durations are what make an interface feel amateur
/// even when every individual animation is fine.
///
/// Everything here is short. Anything a user triggers deliberately and waits
/// on should be under ~250ms; past that it stops reading as responsiveness
/// and starts reading as lag.
abstract class AppMotion {
  AppMotion._();

  // ---------------------------------------------------------------- timing
  //
  // Durations are tiered by **how often the interaction happens**, not by how
  // far something travels. Something you do a hundred times a day cannot
  // afford 250ms; something you do once a session can.
  //
  // Nothing here exceeds 300ms. Past that a UI animation stops reading as the
  // interface responding and starts reading as the interface being slow —
  // and the user is always waiting on the *end* of it.

  /// Tab switches, filter chips, anything on the main path.
  ///
  /// The bottom nav ran at 250ms, which is a quarter of a second of waiting
  /// attached to the single most repeated action in the app.
  static const Duration instant = Duration(milliseconds: 120);

  /// Press feedback. Long enough to be seen, short enough to be over before
  /// the finger lifts.
  static const Duration press = Duration(milliseconds: 160);

  /// The default for anything that moves or resizes on screen.
  static const Duration normal = Duration(milliseconds: 220);

  /// The largest travel in the app — the quick-save sheet and page
  /// transitions. Deliberately 280 rather than the 320 it used to be: 320 was
  /// simply over the line.
  static const Duration sheet = Duration(milliseconds: 280);

  // ---------------------------------------------------------------- easing
  //
  // One curve does almost everything, and it is a *strong* ease-out: nearly
  // all of the movement happens immediately, then it settles. That front-
  // loading is what makes an interface feel like it is reacting to you rather
  // than playing you an animation.

  /// `cubic-bezier(0.23, 1, 0.32, 1)`.
  static const Curve standard = Cubic(0.23, 1, 0.32, 1);

  /// [standard], written so it still front-loads when an animation runs
  /// **backwards**.
  ///
  /// This is subtler than it looks and the app had it wrong. A
  /// [CurvedAnimation] running in reverse still evaluates `reverseCurve` at
  /// the parent's value, and the parent is now counting *down* from 1. A
  /// strong ease-out is almost flat near 1, so handing it back unchanged
  /// means the first ~80ms after pressing back barely move — the exact
  /// ease-in behaviour the curve was chosen to avoid, just arrived at from
  /// the other direction.
  ///
  /// Flipping it puts the steep part of the curve where the reverse
  /// *starts*, so leaving is as immediate as arriving.
  static const Curve standardReverse = FlippedCurve(standard);

  /// `cubic-bezier(0.32, 0.72, 0, 1)` — the drawer curve.
  ///
  /// A named value rather than one invented here: it is the curve behind the
  /// sheet in Vaul, tuned specifically for a surface that travels the height
  /// of a phone. It leaves faster than the standard ease-out and lands
  /// completely flat, so a sheet arrives without the faint bounce a symmetric
  /// curve gives it at that distance.
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Kept as an alias so existing call sites keep their meaning.
  static const Curve emphasis = drawer;

  /// Per-item delay when a list appears for the first time.
  ///
  /// Stagger is decoration, and the skill this came from is explicit that it
  /// is only welcome in rare moments — so it runs **once, on first paint,
  /// and never again**. Attaching it to grid items permanently is what made
  /// this app stutter on scroll before: a recycled tile replays its entrance
  /// every time it comes back into view.
  static const Duration stagger = Duration(milliseconds: 40);

  /// The most an entrance is allowed to be delayed, however long the list is.
  /// Beyond about six items a stagger stops reading as choreography and
  /// starts reading as the list being slow to load.
  static const int maxStaggered = 6;

  /// Things leaving use the **same ease-out**, only faster.
  ///
  /// This used to be `Curves.easeInCubic`, and ease-in is the one thing a UI
  /// must never do: it starts slow, so the first moments after a tap look
  /// like nothing happened. Physical intuition says an exit should accelerate
  /// away; interface intuition says the user pressed a button and deserves an
  /// immediate answer. Interface wins.
  static const Curve exit = standard;

  // ------------------------------------------------------- reduced motion
  //
  // Honoured explicitly because none of the app's motion goes through the
  // Material widgets that respect it for free.

  /// [base], or nothing at all when the user has asked the system to remove
  /// animation.
  ///
  /// Only *movement* is dropped — colour and opacity changes survive, because
  /// removing those would remove meaning rather than motion.
  static Duration duration(BuildContext context, Duration base) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// A first-paint entrance for an item in a list or grid.
///
/// Stagger is decoration, and decoration on a scrolling list is how this app
/// used to stutter: an item recycled back into view replays its entrance
/// every single time, so scrolling turned into a flickering wall. That is why
/// `flutter_animate` was pulled out of the grid earlier in this project.
///
/// It is allowed back under two conditions, both enforced here rather than
/// left to the call site:
///
/// 1. **Only the first few items.** Past [AppMotion.maxStaggered] a stagger
///    stops reading as choreography and starts reading as a slow list.
/// 2. **Only for a moment after the list first appeared.** [since] is stamped
///    once when the list is built; anything constructed after the window has
///    closed appears instantly, which is exactly what a recycled tile does.
class EntranceStagger extends StatefulWidget {
  final int index;

  /// When the list this belongs to was first built.
  final DateTime since;

  final Widget child;

  const EntranceStagger({
    super.key,
    required this.index,
    required this.since,
    required this.child,
  });

  /// How long after [since] an item may still animate in.
  static const Duration window = Duration(milliseconds: 400);

  @override
  State<EntranceStagger> createState() => _EntranceStaggerState();
}

class _EntranceStaggerState extends State<EntranceStagger>
    with SingleTickerProviderStateMixin {
  late final bool _eligible =
      widget.index < AppMotion.maxStaggered &&
      DateTime.now().difference(widget.since) < EntranceStagger.window;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  @override
  void initState() {
    super.initState();
    if (!_eligible) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(AppMotion.stagger * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible || AppMotion.reduced(context)) return widget.child;

    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
    );
    return FadeTransition(
      opacity: curved,
      // From 0.96, never from zero — an item that grows from nothing reads as
      // being created rather than as arriving.
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// A single pop of the [child] whenever [value] changes.
///
/// For controls whose *state* is the whole point — the favourite heart being
/// the only one in this app. Toggling it changes an outline into a filled red
/// shape and nothing else on screen moves, so at a glance it is easy to miss
/// whether the tap registered at all. A brief overshoot is the cheapest way
/// to say "this changed, and it changed because of you".
///
/// This is the one place the app spends its delight budget on an ordinary
/// control, and it earns it by being **rare** — favouriting happens a handful
/// of times a session, not a hundred. It deliberately does not fire on first
/// build, so opening a viewer on an already-favourited screenshot is still.
class ValuePop extends StatefulWidget {
  final Object? value;
  final Widget child;

  /// Peak of the overshoot. Kept near 1.15: past about 1.25 the icon reads as
  /// jumping out of the toolbar rather than reacting inside it.
  final double peak;

  const ValuePop({
    super.key,
    required this.value,
    required this.child,
    this.peak = 1.15,
  });

  @override
  State<ValuePop> createState() => _ValuePopState();
}

class _ValuePopState extends State<ValuePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Out and back inside a quarter second. The rule about staying under
    // 300ms applies to the whole round trip, not to each half of it.
    duration: const Duration(milliseconds: 260),
  );

  /// Out fast, back slower — the same asymmetry as a press: the system
  /// answers immediately, then settles.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: widget.peak,
      ).chain(CurveTween(curve: AppMotion.standard)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: widget.peak,
        end: 1,
      ).chain(CurveTween(curve: AppMotion.standard)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(ValuePop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// How a control answers a press.
enum PressFeedback {
  /// Shrinks slightly. For **discrete objects** — buttons, chips, cards,
  /// thumbnails: things with an edge, that look like they could be pushed.
  scale,

  /// Tints, and moves nothing. For **full-width rows inside a list**.
  ///
  /// This distinction is not decoration, it is the fix for a bug that has now
  /// been reported twice. Press feedback inside a scrollable is unavoidably
  /// *speculative*: the framework cannot know whether a finger that has landed
  /// is about to tap or about to drag, so it reports the press first and
  /// withdraws it once the drag wins. Every platform does this. What differs
  /// is what gets withdrawn — a tint appearing and vanishing is a row
  /// acknowledging a touch, while a row that shrinks and springs back makes
  /// the *page* look like it shuddered, and a list of them shudders in
  /// sequence as the finger passes over each one.
  ///
  /// Delaying the press was tried first and cannot work: it only moves the
  /// threshold, so anybody who rests a finger before dragging — which is what
  /// people do at the end of a long page — still sees it.
  highlight,
}

/// Wraps a tap target so pressing it answers immediately.
///
/// Used instead of Material ink because the app's surfaces are rounded cards
/// on tinted backgrounds, where a ripple has to be clipped to look right and
/// still reads as a grey smear on dark mode. The response is legible on any
/// surface, costs one transform or one fill, and — critically for how "snappy"
/// the app feels — begins on *press down* rather than on release.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// See [PressFeedback]. Defaults to shrinking; rows in a list should say
  /// [PressFeedback.highlight].
  final PressFeedback feedback;

  /// How far it shrinks.
  ///
  /// Clamped to 0.90–0.99 on use. A press that shrinks a control past ~10%
  /// stops reading as a button responding and starts reading as the control
  /// shrinking, and several call sites here had drifted to 0.85 — small
  /// enough to look like a glitch on a large card.
  final double scale;

  final bool haptic;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.feedback = PressFeedback.scale,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  Timer? _pressTimer;

  /// How long a finger must stay put before the control admits it is being
  /// pressed.
  ///
  /// A tap recognizer inside a scrollable reports the press before the gesture
  /// arena has decided whether this is a tap or the start of a scroll, and
  /// withdraws it once the drag wins. Waiting a moment first hides that for
  /// anybody who moves straight away.
  ///
  /// **It does not solve the problem, and it was wrong to think it did.** It
  /// moves the threshold, nothing more: rest a finger for a beat before
  /// dragging — which is exactly what people do when they have been reading —
  /// and the press still lands and is still withdrawn. That is why full-width
  /// rows now use [PressFeedback.highlight], which makes the withdrawal
  /// invisible instead of trying to prevent it.
  ///
  /// Kept because it is still worth having: it is far below the ~80–150ms a
  /// deliberate tap lasts, so a real press feels exactly as immediate.
  static const Duration _slop = Duration(milliseconds: 55);

  /// The scrollable this control lives in, if any.
  ///
  /// Watched so a press is abandoned the instant the list actually starts
  /// moving, and never begins at all on a list that is already moving — the
  /// finger that stops a fling is not pressing anything.
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _scrollPosition)) return;
    _scrollPosition?.isScrollingNotifier.removeListener(_onScrollingChanged);
    _scrollPosition = position;
    _scrollPosition?.isScrollingNotifier.addListener(_onScrollingChanged);
  }

  void _onScrollingChanged() {
    if (_isScrolling) _pressOut();
  }

  bool get _isScrolling => _scrollPosition?.isScrollingNotifier.value ?? false;

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(_onScrollingChanged);
    _pressTimer?.cancel();
    super.dispose();
  }

  void _pressIn() {
    if (_isScrolling) return;
    _pressTimer?.cancel();
    _pressTimer = Timer(_slop, () {
      if (!_isScrolling) _set(true);
    });
  }

  void _pressOut() {
    _pressTimer?.cancel();
    _set(false);
  }

  void _set(bool value) {
    if (_down == value || !mounted) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _pressIn() : null,
      onTapCancel: enabled ? _pressOut : null,
      onTapUp: enabled ? (_) => _pressOut() : null,
      // Haptics itself checks the user's preference, so the call site only
      // has to say whether *this* control should ever buzz — before, both
      // checks lived here and the preference was easy to forget.
      onTap: widget.onTap == null
          ? null
          : () {
              // A tap that resolved faster than the slop above never turned
              // the pressed state on; releasing must still clear the pending
              // timer or the control would shrink after the tap had already
              // been handled.
              _pressOut();
              if (widget.haptic) Haptics.tap();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _pressOut();
              if (widget.haptic) Haptics.longPress();
              widget.onLongPress!();
            },
      child: _feedback(context, enabled),
    );
  }

  /// Press feedback belongs in the 100–160ms band either way: any faster and
  /// it is not seen, any slower and it is still catching up when the finger
  /// lifts.
  Widget _feedback(BuildContext context, bool enabled) {
    final bool pressed = _down && enabled;

    switch (widget.feedback) {
      case PressFeedback.scale:
        return AnimatedScale(
          scale: pressed ? widget.scale.clamp(0.90, 0.99) : 1,
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standard,
          child: widget.child,
        );

      case PressFeedback.highlight:
        // Painted *over* the child rather than behind it: rows draw their own
        // opaque surface colour, so anything underneath would never be seen.
        // Opacity rather than a colour tween so the row's own background can
        // be anything.
        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: pressed ? 1 : 0,
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  child: ColoredBox(
                    // Derived from the text colour, so it darkens on paper and
                    // lightens on near-black without a second token.
                    color: context.colors.textPrimary.withValues(alpha: 0.055),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
