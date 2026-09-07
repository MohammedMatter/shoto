import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:shoto/core/services/native_splash.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// The numbers the native launch artwork is authored to, shared with
/// `tool/generate_brand_assets.dart` so the drawing and the drawing's
/// coordinates cannot drift apart.
///
/// Android specifies a splash icon on a 288dp square with everything inside the
/// middle 192dp, because the platform is free to mask or scale the rest. That
/// is why the curtain can be handed an icon *view* and still know where the ink
/// is: the ink is two thirds of whatever box the platform chose, centred in it.
abstract class SplashMark {
  SplashMark._();

  static const double canvas = 288;
  static const double safeArea = 192;

  /// What fraction of the platform's icon box the drawing actually fills.
  static const double safeAreaRatio = safeArea / canvas;

  /// The ink's aspect, taken from the drawing itself rather than from the box
  /// it is authored on — the bare mark is wider than it is tall.
  static double get inkAspect =>
      ShotoBrandMarkPainter.restBounds.height /
      ShotoBrandMarkPainter.restBounds.width;
}

/// The cold start, continued in Flutter.
///
/// ## What this replaces
///
/// A cold start used to be three pictures. The platform splash showed the mark
/// and left as soon as the activity could draw; then a flat coloured field sat
/// there for one and a half to three seconds while `main` waited on Firebase, a
/// dozen preference loads and a subscription lookup; then the first screen
/// arrived as a hard cut. The mark was on screen for the shortest part of a
/// launch and nothing at all was on screen for the longest part of it.
///
/// ## What it is
///
/// One continuous shot, in three beats.
///
/// **The handover.** `SplashChannel.kt` holds the native splash open and
/// measures the icon it is showing. This draws the same mark at the same size
/// in the same place, waits for that frame to actually be on screen, and only
/// then tells the native side to remove its view. Nothing fades into anything;
/// there is one picture, and the window under it changes owner. See
/// [NativeSplash].
///
/// **The settle.** The mark then travels to where the lockup belongs and comes
/// down to its resting size, and the wordmark arrives under it. This is the
/// only beat that is decoration, and it is free: it plays during time the app
/// was going to spend loading anyway, which is the reason this is put on screen
/// *before* the bootstrap rather than after it. See `main.dart`.
///
/// **The exit.** The wordmark goes first, then the mark, then the field itself
/// dissolves to reveal the app that has been sitting behind it fully built. The
/// field is the last thing to leave, so the reveal reads as one surface lifting
/// rather than as a screen being swapped.
///
/// ## What it must never do
///
/// **Fail to lift.** A curtain that sticks is an app that never starts, and it
/// would be indistinguishable from a hang. Every wait here is bounded: the
/// handover gives up after [_handoffWait] and centres the mark itself, and the
/// exit is gated on [ready] and on nothing else — a bootstrap that throws still
/// sets it. The native side carries the same discipline; see the notes there.
class SplashCurtain extends StatefulWidget {
  /// Whether the app behind the curtain is built and laid out.
  ///
  /// The exit is gated on this and on nothing else. It is deliberately *not*
  /// gated on anything the curtain itself could fail to observe.
  final bool ready;

  /// The background the app is actually going to wake up in, and the colour it
  /// sets text in.
  ///
  /// **This exists for one case, and it is not a rare one.** The launch field
  /// is resolved by Android against the *system's* mode, because on Android 12
  /// and up the platform builds its splash window before this app's process
  /// exists — there is no moment at which any code of ours could tell it that
  /// the user has pinned light inside Shoto on a phone that is in dark mode.
  /// Measured on the phone this was built against, which is in exactly that
  /// state: the system reports night, Shoto is pinned light, so the launch
  /// window is near-black and the app behind it is near-white.
  ///
  /// Handing that over as a cut would be the original bug in a new place. So
  /// the field **travels** — it starts as whatever Android painted, matching it
  /// exactly for the handover, and moves to this while the mark is settling.
  /// The exit is then a plain reveal onto a field that already agrees with what
  /// is underneath it.
  ///
  /// **During the settle rather than during the exit**, because the settle is
  /// time the app was going to spend loading anyway and the exit is not. A
  /// full-screen colour change is a large event; it belongs in the half-second
  /// nobody is waiting on, not in the half-second where the app is arriving.
  ///
  /// When the two agree — every launch where the user has not pinned a mode
  /// against their system — this is a lerp between a colour and itself and
  /// nothing happens at all.
  final ({Color field, Color ink}) destination;

  /// Called once the field has fully dissolved and there is nothing left to
  /// draw. The parent takes the curtain out of the tree here.
  final VoidCallback onGone;

  const SplashCurtain({
    super.key,
    required this.ready,
    required this.destination,
    required this.onGone,
  });

  /// Whether the curtain is on screen right now.
  ///
  /// **Read by whichever screen the router opened at launch, to tell "I am the
  /// first thing this app is showing" from "somebody navigated to me".** The
  /// sign-in screen files the mark's three cards in as it arrives, which is a
  /// good animation once and a stutter twice — nobody who has just watched that
  /// same mark settle in the middle of the same screen needs to watch it
  /// assemble again in the corner of it a moment later.
  ///
  /// It has to be *is up* rather than *has played*, and the difference is a
  /// real case rather than a hypothetical one: a first install goes to
  /// onboarding, and reaches sign-in by pushing a route minutes later. The
  /// curtain played at launch and is long gone, and the mark filing itself on
  /// arrival is exactly right there. A process-lifetime "played" flag would
  /// have silently killed it.
  static bool get isUp => _isUp;
  static bool _isUp = false;

  @override
  State<SplashCurtain> createState() => _SplashCurtainState();
}

/// How long the mark takes to leave the platform's geometry and come to rest.
const Duration _settleDuration = Duration(milliseconds: 520);

/// How long the whole thing takes to get out of the way.
///
/// Longer than `AppMotion.sheet`, and allowed to be: this is not a response to
/// a tap and nobody is waiting on the end of it. The app underneath is finished
/// and legible well before the field has finished going.
///
/// It has to cover four overlapping things — the wordmark leaving, the mark
/// leaving, the field changing colour where it has to, and the app being
/// revealed — and every one of them is shorter than this. Nothing here queues.
const Duration _leaveDuration = Duration(milliseconds: 520);

/// The longest the handover is held back waiting for the native side to say
/// where its icon was.
///
/// Nothing is lost by waiting: the native splash is still on top of us for all
/// of it, so the screen is not blank, it is the launch screen. What is lost by
/// *not* waiting is the entire point of the mechanism — releasing early means
/// handing over from a measured rectangle to a guessed one.
const Duration _handoffWait = Duration(milliseconds: 400);

/// The mark's resting ink width, in logical pixels.
///
/// Smaller than the platform's 192dp icon, which is what makes the settle read
/// as the mark coming to rest rather than merely sliding across. It also has to
/// leave room for a wordmark inside the same optical block.
const double _restingInk = 132;

/// Between the mark's ink and the top of the wordmark.
const double _wordGap = 30;

/// The wordmark, set the way the launch artwork used to set it before it moved
/// in here out of a pair of baked rasters.
///
/// Wide tracking on a five-letter word in the app's own display face. It is the
/// one place the product's name is drawn rather than typed, and the
/// letter-spacing is what stops five capitals reading as an abbreviation.
const double _wordSize = 22;
const double _wordTracking = 0.30;

/// Where the lockup's optical centre sits, as a fraction of the screen.
///
/// Above the true middle. A block centred by arithmetic reads as low, because
/// the eye puts the centre of a page above its half-way line — the same reason
/// a picture hung at exactly half height looks like it has slipped.
const double _lockupCentre = 0.455;

/// The field, and the ink the wordmark is set in, for one system brightness.
///
/// **Resolved from the platform's brightness rather than from `ThemeController`,
/// and it has to be.** The controller is loaded inside the bootstrap this
/// curtain is drawn in front of — asking it anything here would mean waiting
/// for the thing the curtain exists to cover. The platform's answer is also the
/// *right* one to match: it is what Android resolved `values-night` against
/// when it painted the launch window a few hundred milliseconds ago, so the two
/// agree by construction rather than by a value somebody has to keep in step.
///
/// Somebody who has pinned a mode inside Shoto against their phone's is the one
/// case where the field is not the app's own background. It costs nothing here
/// that it used to cost: the field does not have to hand over to a matching
/// colour any more, it dissolves, and what is revealed underneath is whatever
/// the app really is.
///
/// The palette is read rather than transcribed. `values/colors.xml` and its
/// `night` twin hold the same two values, and that pair is the one thing here
/// with no mechanism to check it.
({Color field, Color ink}) _field(BuildContext context, Color? sampled) {
  // What the launch window is really showing beats what it was told to show.
  // A vendor dark mode can repaint that window between the theme specifying it
  // and anybody seeing it — measured, on the phone this was built against — and
  // the handover is a claim about the glass, not about the theme.
  final Color field =
      sampled ??
      (MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? AppPalette.canvasDark
          : AppPalette.canvasLight);

  // Derived from the field rather than from the palette, for the same reason.
  // A sampled field may be a colour neither palette contains, and a wordmark
  // picked from a palette that disagrees with it is unreadable.
  return (
    field: field,
    ink: ThemeData.estimateBrightnessForColor(field) == Brightness.dark
        ? AppPalette.paper
        : AppPalette.ink,
  );
}

class _SplashCurtainState extends State<SplashCurtain>
    with TickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: _settleDuration,
  );

  late final AnimationController _leave = AnimationController(
    vsync: this,
    duration: _leaveDuration,
  );

  /// Null until the native side answers, and null forever where there is
  /// nothing to answer. See [_inkRect] for what happens then.
  SplashHandoff? _handoff;

  /// Set once the native splash has been told it may go. Until then this widget
  /// is drawing *underneath* a launch screen the user is still looking at,
  /// which is precisely what makes repositioning the mark free.
  bool _handedOver = false;

  /// Reduced motion: the mark holds the platform's geometry and never travels.
  /// Only the fades run — an opacity carries meaning, and removing the app's
  /// name would be removing meaning rather than motion.
  bool _still = false;

  bool _leaving = false;

  /// The field Android actually painted, **captured once and never re-read.**
  ///
  /// It has to be frozen. `NativeSplash.pinNightMode` runs during startup and
  /// can flip this process's reported brightness *while the curtain is on
  /// screen* — which is the correct thing for it to do, and would make a field
  /// read afresh every frame jump from one mode to the other in a single frame.
  /// That is the hard cut this whole class exists to remove, arriving through
  /// the fix for it.
  ///
  /// What the handover has to match is what the launch window was painted in,
  /// which is a fact about the past. Everything after it travels there
  /// deliberately, through [SplashCurtain.destination].
  ({Color field, Color ink}) _launch = (
    field: AppPalette.canvasDark,
    ink: AppPalette.paper,
  );
  bool _captured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_captured) return;
    _captured = true;
    _launch = _field(context, NativeSplash.handoff.value?.field);
  }

  @override
  void initState() {
    super.initState();
    SplashCurtain._isUp = true;
    NativeSplash.handoff.addListener(_onHandoff);
    NativeSplash.begin();
    unawaited(_handOver());
  }

  @override
  void didUpdateWidget(SplashCurtain old) {
    super.didUpdateWidget(old);
    _maybeLeave();
  }

  @override
  void dispose() {
    // Also here, not only on a completed exit: a curtain torn down without
    // finishing — a hot restart, a failure further up the tree — must not leave
    // the flag standing, or every screen after it reads as a launch.
    SplashCurtain._isUp = false;
    NativeSplash.handoff.removeListener(_onHandoff);
    _settle.dispose();
    _leave.dispose();
    super.dispose();
  }

  void _onHandoff() {
    if (!mounted) return;
    setState(() {
      _handoff = NativeSplash.handoff.value;
      // The sampled field arrives with the rectangle, and both arrive before
      // the handover — the native side is still holding its splash over us
      // until Dart says otherwise, so adopting a truer colour here is free and
      // invisible. After that this must never move again; see [_launch].
      if (!_handedOver) _launch = _field(context, _handoff?.field);
    });
  }

  /// Draws the matching frame, proves it is on screen, and only then lets the
  /// native splash go.
  ///
  /// The order is the whole trick. `endOfFrame` resolves after the frame has
  /// been handed to the rasteriser, so by the time [NativeSplash.release] is
  /// called there is genuinely a picture underneath the one being removed.
  /// Releasing a frame early is not a subtle bug — it is a flash of bare app
  /// background between two identical images.
  Future<void> _handOver() async {
    await _awaitHandoff();
    if (!mounted) return;

    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    NativeSplash.release();
    setState(() {
      _handedOver = true;
      _still = AppMotion.reduced(context);
    });

    await _settle.forward();
    _maybeLeave();
  }

  /// Waits for the measured rectangle, but never for longer than
  /// [_handoffWait].
  Future<void> _awaitHandoff() async {
    if (_handoff != null) return;

    final Completer<void> arrived = Completer<void>();
    void listener() {
      if (!arrived.isCompleted) arrived.complete();
    }

    NativeSplash.handoff.addListener(listener);
    await Future.any(<Future<void>>[
      arrived.future,
      Future<void>.delayed(_handoffWait),
    ]);
    NativeSplash.handoff.removeListener(listener);
  }

  void _maybeLeave() {
    if (_leaving || !mounted) return;
    if (!widget.ready || !_handedOver || !_settle.isCompleted) return;

    _leaving = true;
    // One frame of grace, so the screen that was just built has been laid out
    // and rasterised before any of it becomes visible. Revealing a subtree on
    // the same frame it was mounted is how a "smooth" transition ends up
    // showing half a screen.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _leave.forward();
      SplashCurtain._isUp = false;
      if (mounted) widget.onGone();
    });
  }

  /// Where the mark's ink is, at the current moment of the film.
  ///
  /// **The fallback matters as much as the measured path.** With no handoff —
  /// iOS, a platform that gave us no icon to measure, a device that took too
  /// long to answer — the mark simply starts where it was going to end up. Not
  /// the same screen, but a correct one: it degrades to the launch every app
  /// has, rather than to a mark in the wrong place.
  Rect _inkRect(Size screen, double settle) {
    final SplashHandoff? from = _handoff;

    final Rect resting = _rectFor(
      Offset(
        screen.width / 2,
        screen.height * _lockupCentre - (_wordGap + _wordSize) / 2,
      ),
      _restingInk,
    );

    if (from == null) return resting;

    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final Rect measured = _rectFor(
      from.centre / dpr,
      from.size / dpr * SplashMark.safeAreaRatio,
    );

    return Rect.lerp(measured, resting, settle)!;
  }

  Rect _rectFor(Offset centre, double inkWidth) => Rect.fromCenter(
    center: centre,
    width: inkWidth,
    height: inkWidth * SplashMark.inkAspect,
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_settle, _leave]),
          builder: (BuildContext context, Widget? _) {
            final _CurtainPainter painter = _CurtainPainter(
              launch: _launch,
              destination: widget.destination,
              // **Behind the mark's own travel, and ending before it does.**
              // The field holds the launch colour for the first fifth of the
              // settle, which is the part still close enough to the handover to
              // be read as the same picture, and has finished changing while
              // the mark is still coming to rest — so the last thing that moves
              // is the mark landing, not the background catching up with it.
              resolved: AppMotion.standard.transform(
                ((_settle.value - 0.20) / 0.60).clamp(0.0, 1.0),
              ),
              ink: _inkRect(
                MediaQuery.sizeOf(context),
                _still ? 0 : AppMotion.drawer.transform(_settle.value),
              ),
              // The wordmark arrives in the back half of the settle, once the
              // mark has all but stopped. Two things moving at once read as one
              // busy screen; one landing and then the other reads as a
              // sentence.
              wordIn: AppMotion.standard.transform(
                ((_settle.value - 0.45) / 0.55).clamp(0.0, 1.0),
              ),
              leave: _leave.value,
            );

            // **Declared, so the bars follow the field rather than the app that
            // is not visible yet.**
            //
            // [MyApp] is mounted underneath while the curtain is still opaque,
            // and it sets an overlay style for the screen it is about to show.
            // Without this the status-bar icons would flip to the destination's
            // a frame after that mount — which on the mismatched launch this
            // whole mechanism exists for means dark icons on a near-black
            // field, invisible for the length of the exit. An annotation above
            // it in the tree wins, and it is computed from the colour actually
            // being painted, so the icons turn over exactly when the field
            // does.
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: _bars(painter.fieldColour),
              child: CustomPaint(size: Size.infinite, painter: painter),
            );
          },
        ),
      ),
    );
  }

  /// System bars for a field of [field]: transparent, with icons on whichever
  /// side of it can be seen.
  SystemUiOverlayStyle _bars(Color field) {
    final Brightness icons = ThemeData.estimateBrightnessForColor(field) ==
            Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: icons == Brightness.light
          ? Brightness.dark
          : Brightness.light,
      systemNavigationBarColor: field,
      systemNavigationBarIconBrightness: icons,
    );
  }
}

/// Everything the curtain draws, in one pass: the field, the mark, the wordmark.
///
/// **A painter rather than a column of widgets**, for two reasons that both
/// matter on the first frame of a cold start. It is one paint with no layout
/// and no layers, at the moment the engine is busiest. And the wordmark is
/// artwork rather than interface — painted text is immune to the system font
/// scale, which a `Text` is not, and a launch lockup whose name reflows at 130%
/// type is not a lockup.
class _CurtainPainter extends CustomPainter {
  /// The field the launch window was painted in, and the ink the wordmark is
  /// set in against it. See [_field].
  final ({Color field, Color ink}) launch;

  /// Where the field is going. See [SplashCurtain.destination].
  final ({Color field, Color ink}) destination;

  /// How far along that journey the field is: 0 at the handover, 1 once the
  /// mark has settled.
  final double resolved;

  /// The mark's ink — not its 100×100 box. See
  /// [ShotoBrandMarkPainter.restBounds].
  final Rect ink;

  /// 0 — the wordmark is not there yet. 1 — fully arrived.
  final double wordIn;

  /// 0 — the curtain is whole. 1 — nothing is left of it.
  final double leave;

  _CurtainPainter({
    required this.launch,
    required this.destination,
    required this.resolved,
    required this.ink,
    required this.wordIn,
    required this.leave,
  });

  /// **The four windows of the exit, and every one of them overlaps its
  /// neighbour.** Blocks that queue read as a list being dismantled; blocks
  /// that overlap read as one thing leaving.
  ///
  /// The order is fixed by what each one is for. The wordmark goes first — last
  /// in, first out. The mark goes under it, so the two read as one object being
  /// taken away rather than as two. The field only *changes colour* once the
  /// lockup is most of the way gone, because a full-screen colour move under a
  /// logo would drag the eye off the logo. And the field is the last thing to
  /// dissolve, so the reveal is one surface lifting rather than a screen being
  /// swapped.
  static const double _wordTo = 0.22;
  static const double _markFrom = 0.04;
  static const double _markTo = 0.48;
  static const double _fieldFrom = 0.30;

  /// The field's colour at this moment.
  ///
  /// Read by the curtain as well as painted here, so the system bars turn over
  /// on exactly the same schedule as the thing behind them.
  Color get fieldColour =>
      Color.lerp(launch.field, destination.field, resolved)!;

  /// The wordmark's colour, on the same journey.
  ///
  /// It has to travel with the field rather than being picked once. The launch
  /// ink is chosen to read on the launch field; leave it there while the field
  /// crosses to the other mode and the name fades out into its own background
  /// halfway through.
  Color get inkColour => Color.lerp(launch.ink, destination.ink, resolved)!;

  @override
  void paint(Canvas canvas, Size size) {
    final double fieldAlpha = 1 - _span(leave, _fieldFrom, 1);
    if (fieldAlpha <= 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = fieldColour.withValues(alpha: fieldAlpha),
    );

    final double markAlpha = 1 - _span(leave, _markFrom, _markTo);
    if (markAlpha > 0) _paintMark(canvas, size, markAlpha);

    final double wordAlpha = wordIn * (1 - _span(leave, 0, _wordTo));
    if (wordAlpha > 0) _paintWord(canvas, wordAlpha);
  }

  void _paintMark(Canvas canvas, Size size, double alpha) {
    // The whole exit is a shrink of about six percent. Enough to say the object
    // is going away from the viewer, small enough that it never competes with
    // the field lifting, which is what the eye is actually meant to follow.
    final double scale = 1 - 0.06 * _span(leave, _markFrom, _markTo);
    final double inkWidth = ink.width * scale;
    final double extent = ShotoBrandMarkPainter.extentForInkWidth(inkWidth);

    final bool layered = alpha < 1;
    if (layered) {
      canvas.saveLayer(
        ink.inflate(2),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }

    ShotoBrandMarkPainter(
      markExtent: extent,
      backdrop: false,
      centre: ShotoBrandMarkPainter.centreForInk(ink.center, extent),
    ).paint(canvas, size);

    if (layered) canvas.restore();
  }

  void _paintWord(Canvas canvas, double alpha) {
    final TextPainter word = TextPainter(
      text: TextSpan(
        text: 'SHOTO',
        style: TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: _wordSize,
          // Archivo is a variable face registered once at 400. The axis is what
          // selects a real semibold; `fontWeight` alone would match the same
          // file and let the engine thicken the outlines itself, which is a
          // blur rather than a typeface. See pubspec.
          fontVariations: const <FontVariation>[FontVariation('wght', 600)],
          fontWeight: FontWeight.w600,
          letterSpacing: _wordSize * _wordTracking,
          color: inkColour.withValues(alpha: alpha),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      // Artwork, not interface: the lockup is drawn at the size it was designed
      // at, whatever the user has done to their system font size.
      textScaler: TextScaler.noScaling,
    )..layout();

    // Tracking is applied after the last letter too, which pushes the drawn
    // block half a space left of true centre. Correcting it is the difference
    // between a wordmark that sits under the mark and one that *looks* like it
    // does.
    final double left =
        ink.left + (ink.width - word.width + _wordSize * _wordTracking) / 2;

    // Six pixels of rise, spent entirely on the arrival. It is the only travel
    // the wordmark ever does, and without it the name simply switches on.
    final double rise = (1 - wordIn) * 6 - _span(leave, 0, _wordTo) * 3;

    word.paint(canvas, Offset(left, ink.bottom + _wordGap + rise));
  }

  /// [value]'s progress through the window [from]..[to], clamped.
  static double _span(double value, double from, double to) =>
      ((value - from) / (to - from)).clamp(0.0, 1.0);

  @override
  bool shouldRepaint(_CurtainPainter old) =>
      old.ink != ink ||
      old.wordIn != wordIn ||
      old.leave != leave ||
      old.resolved != resolved ||
      old.launch != launch ||
      old.destination != destination;
}
