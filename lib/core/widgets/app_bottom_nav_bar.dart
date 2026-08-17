import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A floating frosted tab bar, in the shape iOS uses: a pill held off the
/// bottom of the screen with the page running underneath it.
///
/// This surface has been through four versions, and the difference between the
/// ones that failed and this one is **not the blur** — it is what colour sits
/// on top of it.
///
/// 1. Frost at sigma 30, a white sheen and a 35%-black ambient shadow. The
///    shadow was the problem: a wide dark blur on a near-black canvas is a
///    smudge, and it made the bar the heaviest object in a deliberately quiet
///    interface. (That shadow is now gone from the whole app — see
///    [AppPalette].)
/// 2. No bar at all — items straight over the page. Honest, and unreadable
///    over a library of other people's screenshots.
/// 3. Flat `graphite` at 70%, then 90%. A mid grey is the universal language
///    of *disabled*, which is exactly why [AppPalette.marker] refuses to be
///    one, and at 90% it stopped being translucent at all.
/// 4. Frost with a fill **lighter than the canvas** — `#3D3D3D` over a
///    `#1A1A1A` page. This is the interesting failure: it read as fog. A
///    translucent layer that is lighter than what it covers doesn't look like
///    glass over content, it looks like content behind haze, because raising
///    every pixel towards mid grey is what haze does.
///
/// So: the fill is **darker than the canvas and barely there** — a few points
/// down from [AppPalette.background], at just over half alpha. The blur does the
/// separating and the fill only settles it, which is the way round it has to be
/// for glass. The screenshots scrolling underneath stay visible as soft shape
/// and colour, which is the entire cue that this bar is floating over the page
/// rather than sitting in a strip cut out of the bottom of it.
///
/// Two things it deliberately doesn't have: a shadow, and a blur it can't
/// afford. This is the one surface on screen in every tab all the time, over
/// whatever is scrolling, and a `BackdropFilter` re-blurs on every frame in
/// which the pixels behind it change — so it takes [AppBlur.bar], the smallest
/// sigma in the app. Separation comes from the blur and the lit edge
/// ([GlassRim]) instead of from darkness underneath.
///
/// ## It stops blurring while the page is moving, and that is the whole fix
///
/// The smallest sigma in the app was still not small enough. Measured on the
/// test phone in a **profile** build, a few seconds of scrolling Settings
/// produced **125 frames over budget, the worst at 62ms of raster** — against
/// **1 frame** with this bar's blur switched off, on the same swipes. Home was
/// 115 against 2. Dart build time was 0.4ms throughout, so none of it was the
/// widget tree: it was this one surface, re-filtering the region behind it
/// sixty times a second because the region behind it kept changing. That phone
/// runs Impeller on OpenGLES — its Vulkan context fails and the engine falls
/// back — where a backdrop filter costs a full copy of what it covers.
///
/// So the blur is spent where it is actually looked at. While a page is
/// scrolling the bar goes solid; when it stops, the glass comes back.
///
/// **What makes this cheap to do and hard to see is the fill's colour.** It is
/// two points off the canvas by design — see the four failures above — so a
/// fully opaque version of it is *the same object* over the bare page, and the
/// swap is invisible on every part of every screen that is empty. It shows only
/// where there is content under the bar, which is precisely where a blur that
/// is about to be dropped would otherwise leave text legible straight through
/// it.
///
/// **The swap is instant, and the first version got that wrong.** It faded the
/// fill up over [AppMotion.instant] and down over [AppMotion.normal], so that
/// the blur was only dropped once the fill had covered and the content softened
/// back in rather than snapping. It was measured, and it recovered less than
/// half of the loss: **80 janky frames instead of 125**, where switching the
/// blur off outright gives 1.
///
/// The reason is the thing the fade was trying to be polite about. A
/// `BackdropFilter` re-filters when the pixels behind it change **or when its
/// own child does** — and a fill whose alpha moves every frame is its own child
/// changing every frame. So each fade was another 130ms of the exact work the
/// swap exists to avoid, twice per scroll, and the fade-out was spending it
/// while the page was already still.
///
/// Instant also removes the problem the fade was sequenced around. The worry
/// was a window of frames in which the bar has stopped blurring and has nothing
/// over it yet, with the page legible straight through it — which a screenshot
/// of the sigma-zero probe showed, a row of settings text reading cleanly
/// across the middle of the bar. Changing both in the *same frame* means there
/// is no window at all.
///
/// The precedent is in this codebase already: `SheetSurface` spends its whole
/// entrance at sigma zero for the same reason, and [AppBlur.overPhoto] is a
/// blur deleted outright on the same measurement.
class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;

  /// True while the page under the bar is moving.
  ///
  /// Optional, and the bar is plain glass without it: a caller that has no
  /// scrollable underneath — the golden test, or any future screen that mounts
  /// the bar over something static — has nothing to tell it, and should not
  /// have to pass a notifier that would never fire.
  final ValueListenable<bool>? scrolling;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.scrolling,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  /// True while the page under the bar is moving: solid, and not blurring.
  bool _solid = false;

  @override
  void initState() {
    super.initState();
    widget.scrolling?.addListener(_onScrollingChanged);
    _solid = widget.scrolling?.value ?? false;
  }

  @override
  void didUpdateWidget(AppBottomNavBar old) {
    super.didUpdateWidget(old);
    if (identical(old.scrolling, widget.scrolling)) return;
    old.scrolling?.removeListener(_onScrollingChanged);
    widget.scrolling?.addListener(_onScrollingChanged);
    _onScrollingChanged();
  }

  @override
  void dispose() {
    widget.scrolling?.removeListener(_onScrollingChanged);
    super.dispose();
  }

  void _onScrollingChanged() {
    final bool solid = widget.scrolling?.value ?? false;
    if (solid == _solid || !mounted) return;
    setState(() => _solid = solid);
  }

  /// One value, read by the clip, the rim and the fill. A blur clipped to a
  /// shape the edge traces differently is the standard way a glass surface ends
  /// up with a fringe down one side.
  ///
  /// Larger than half the bar's height on purpose: a radius past that point is
  /// capped at exactly semicircular rather than overshooting, so the pill stays
  /// a pill at any text scale.
  static const BorderRadius _shape = BorderRadius.all(Radius.circular(40));

  @override
  Widget build(BuildContext context) {
    // iOS floating tab bars sit a fixed distance above the home-indicator
    // safe area rather than a hardcoded margin, so it lands in the same
    // spot on notched and non-notched devices alike.
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    // The contents never change with the fill, so they are built once here and
    // handed through the builder's `child` slot rather than re-inflated on
    // every frame of a fade.
    final Widget contents = Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
      child: Row(
        children: List.generate(widget.items.length, (index) {
          return Expanded(
            child: _NavItemView(
              item: widget.items[index],
              isActive: index == widget.currentIndex,
              // Only the tab you aren't on buzzes. Switching tabs is
              // the most frequent interaction in the app, and
              // vibrating when nothing changed teaches people to stop
              // trusting the feedback.
              onTap: () {
                if (index != widget.currentIndex) Haptics.tap();
                widget.onTap(index);
              },
            ),
          );
        }),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        0,
        20.w,
        bottomInset > 0 ? bottomInset + 8.h : 16.h,
      ),
      child: GlassLayer(
        borderRadius: _shape,
        // Dropped in the same frame the fill goes opaque, never before it: on
        // any frame where the bar has stopped blurring and has nothing over it
        // yet, the page reads straight through it — which is what a screenshot
        // of the sigma-zero probe showed, a row of settings text reading
        // cleanly across the middle of the bar.
        sigma: _solid ? 0 : AppBlur.bar,
        child: GlassRim(
          borderRadius: _shape,
          // Short, because the pill is short: the light should be gone by
          // halfway down rather than tracing the whole outline.
          falloff: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Both stops sit within a few points of the canvas value, and
                // *never below it*. A fill darker than the page is the third
                // way this bar has been got wrong: `#141414` under a `#1A1A1A`
                // canvas is a black band across the bottom of every screen, and
                // no amount of blur hides it, because the band is not the blur
                // — it is a dark rectangle with a rounded edge.
                //
                // The rule the two failures actually taught: a material takes
                // its value from what is behind it and lifts it slightly.
                // Lifting it by thirty points at high alpha is fog; dropping it
                // below is a slab; a couple of points at just under half alpha
                // is glass. Over the bare page the bar is then almost nothing —
                // which is correct, and why [GlassRim] is what gives it its
                // shape.
                // Both dark stops moved down with the canvas, keeping the
                // offsets the paragraph above describes exactly: +10 and +2
                // from `AppPalette.canvasDark`. They were `#242424`/`#1C1C1C`
                // against a `#1A1A1A` page; against `#121212` those same
                // literals would sit 18 and 10 points *above* it, which is the
                // fog failure this comment already warns about — the values
                // are only correct relative to a canvas, so they have to move
                // when it does.
                //
                // The *same two colours* when the blur goes, only opaque — see
                // the class docstring. Because both sit within a couple of points
                // of the canvas, the solid version of this bar is indentical to
                // the glass one everywhere the page behind it is empty, and the
                // swap is only visible where there was something to see through.
                colors: context.colors.isDark
                    ? [
                        const Color(0xFF1B1C1D).withValues(alpha: _fill(0.44)),
                        const Color(0xFF131415).withValues(alpha: _fill(0.56)),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: _fill(0.58)),
                        const Color(0xFFF4F4F4).withValues(alpha: _fill(0.7)),
                      ],
              ),
              borderRadius: _shape,
            ),
            child: contents,
          ),
        ),
      ),
    );
  }

  /// A fill stop's alpha, in whichever state the bar is in.
  ///
  /// Not quite 1 when solid. A stop at a flat 1.0 makes the bar a plain
  /// rectangle of paint, and the last percent of transparency is what keeps a
  /// hair of whatever is behind it — enough that the pill still reads as a
  /// material rather than a cut-out, and far too little to read any text
  /// through.
  double _fill(double rest) => _solid ? 0.985 : rest;
}

class _NavItemView extends StatelessWidget {
  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemView({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  /// The most-pressed control in the app, so the shortest duration in it.
  ///
  /// 250ms was a quarter of a second attached to every single tab change —
  /// the kind of delay you stop noticing consciously and start feeling as
  /// "this app is a bit slow".
  static const Duration _duration = AppMotion.instant;
  static const Curve _curve = AppMotion.standard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, _duration),
        curve: _curve,
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(vertical: 5.h),
        // **The active tab was a solid slab of the accent and is now a wash.**
        //
        // A filled chip is unambiguous and it was also the single largest area
        // of accent anywhere in the app — on screen in every tab, permanently,
        // on a bar whose entire design above is an argument about staying
        // quiet. A frosted pill with an opaque block sitting inside it is not
        // glass any more, it is a slab with a glass surround.
        //
        // The wash keeps the shape and drops the weight, and the signal moves
        // to where it costs nothing: the icon and the label take the accent
        // and the label goes semibold, so "you are here" is carried by three
        // cues at once rather than by one large rectangle. Non-active items
        // are unchanged, which is what preserves the contrast between them.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isActive
              ? context.colors.primary.withValues(alpha: 0.16)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32.w,
              height: 26.w,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 19.sp,
                color: isActive
                    ? context.colors.primary
                    : context.colors.textSecondary,
              ),
            ),
            // The label is what makes a four-tab bar readable. With icons
            // alone, "Home" and "Library" are two rectangles and the user
            // has to learn them by trial.
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption
                  .weight(
                    isActive ? AppTypography.semiBold : AppTypography.regular,
                  )
                  .copyWith(
                    fontSize: 9.5.sp,
                    height: 1,
                    color: isActive
                        ? context.colors.primary
                        : context.colors.textSecondary,
                  ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }
}
