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
///    [AppColors].)
/// 2. No bar at all — items straight over the page. Honest, and unreadable
///    over a library of other people's screenshots.
/// 3. Flat `graphite` at 70%, then 90%. A mid grey is the universal language
///    of *disabled*, which is exactly why [AppColors.marker] refuses to be
///    one, and at 90% it stopped being translucent at all.
/// 4. Frost with a fill **lighter than the canvas** — `#3D3D3D` over a
///    `#1A1A1A` page. This is the interesting failure: it read as fog. A
///    translucent layer that is lighter than what it covers doesn't look like
///    glass over content, it looks like content behind haze, because raising
///    every pixel towards mid grey is what haze does.
///
/// So: the fill is **darker than the canvas and barely there** — a few points
/// down from [AppColors.background], at just over half alpha. The blur does the
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
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        0,
        20.w,
        bottomInset > 0 ? bottomInset + 8.h : 16.h,
      ),
      child: GlassLayer(
        borderRadius: _shape,
        sigma: AppBlur.bar,
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
                colors: AppColors.isDark
                    ? [
                        const Color(0xFF242424).withValues(alpha: 0.44),
                        const Color(0xFF1C1C1C).withValues(alpha: 0.56),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.58),
                        const Color(0xFFF4F4F4).withValues(alpha: 0.7),
                      ],
              ),
              borderRadius: _shape,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
              child: Row(
                children: List.generate(items.length, (index) {
                  return Expanded(
                    child: _NavItemView(
                      item: items[index],
                      isActive: index == currentIndex,
                      // Only the tab you aren't on buzzes. Switching tabs is
                      // the most frequent interaction in the app, and
                      // vibrating when nothing changed teaches people to stop
                      // trusting the feedback.
                      onTap: () {
                        if (index != currentIndex) Haptics.tap();
                        onTap(index);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: isActive ? AppColors.primaryGradient : null,
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
                color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
            // The label is what makes a four-tab bar readable. With icons
            // alone, "Home" and "Library" are two rectangles and the user
            // has to learn them by trial.
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption
                  .weight(
                    isActive ? AppTextStyles.semiBold : AppTextStyles.regular,
                  )
                  .copyWith(
                    fontSize: 9.5.sp,
                    height: 1,
                    color: isActive
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                  ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }
}
