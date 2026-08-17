import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// The three modes, each shown as the screen it produces.
///
/// **A picture of the answer rather than a symbol for it**, which is the whole
/// difference between this and [ThemeModeSelector]. That control is three
/// glyphs in a segmented pill and it is the right shape where it still lives —
/// beside a label, on a row, in a list of other rows. On a page whose subject
/// *is* how the app looks, a sun and a moon are a description of a choice the
/// page could simply show.
///
/// So each card is painted in the canvas it selects: light mode's card is
/// `canvasLight`, dark mode's is `canvasDark`, and System is both, split down
/// the middle. Nothing here is a mock-up — the values come out of the palette,
/// so a card cannot go stale against the theme it advertises.
///
/// Laid out in a row that scrolls horizontally even though three fit on every
/// phone this ships to. That is not speculation about a fourth mode; it is
/// what stops the three from being squeezed on a 320dp screen at the largest
/// font scale, where a fixed row would have to shrink the cards until the
/// preview stopped being one.
class ThemeCardSelector extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeCardSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// **Sized so all three fit at the design width, rather than trusting the
  /// scroll to cover for them.** At 104 the row measured 336dp against the
  /// 320dp between this page's gutters, so on an ordinary phone the Dark card
  /// was cut off by the edge of the screen — which does not read as "there is
  /// more to the right", it reads as a layout that ran out of room. 98 leaves
  /// two points of slack. The list stays horizontal for the case the note above
  /// describes: a narrow screen at the largest font scale, where something has
  /// to give and a scroll is the only thing that can give without shrinking the
  /// preview until it stops being one.
  static double get _cardWidth => 98.w;
  static double get _cardHeight => 86.h;

  @override
  Widget build(BuildContext context) {
    final List<(ThemeMode, String)> modes = <(ThemeMode, String)>[
      (ThemeMode.system, context.l10n.settingsThemeSystem),
      (ThemeMode.light, context.l10n.settingsThemeLight),
      (ThemeMode.dark, context.l10n.settingsThemeDark),
    ];

    return SizedBox(
      // The label under the card is part of the control's height, so the box
      // has to allow for it or the row clips its own captions.
      height: _cardHeight + 30.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: modes.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (BuildContext context, int index) {
          final (ThemeMode mode, String label) = modes[index];
          return _ThemeCard(
            mode: mode,
            label: label,
            isSelected: mode == value,
            onTap: () => onChanged(mode),
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.95,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // **The selection ring is drawn on the card, inside its own width.**
          //
          // A border added on selection would widen the card by two pixels and
          // shove the two beside it along; this one is always there and only
          // its colour changes — transparent when unselected, the accent when
          // chosen. Same rule as the swatches: nothing in a picker may resize
          // when it is picked.
          AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
            width: ThemeCardSelector._cardWidth,
            height: ThemeCardSelector._cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            // Clipped one step inside the border so the painted canvas does
            // not sit on top of the ring that is meant to frame it.
            child: Padding(
              padding: EdgeInsets.all(isSelected ? 2.5 : 3.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md - 4),
                child: _Preview(mode: mode),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption
                .weight(
                  isSelected ? AppTypography.semiBold : AppTypography.regular,
                )
                .copyWith(
                  color: isSelected
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// What the mode actually looks like: the canvas, with a scrap of the app
/// drawn on it.
///
/// The two bars are a title and a line of body text at roughly the proportions
/// the real thing uses. They exist because a flat rectangle of `#F4F4F4` and
/// one of `#111213` are distinguishable but say nothing — a *page* in each
/// mode is the thing being chosen, and two strokes are enough to read as one.
class _Preview extends StatelessWidget {
  final ThemeMode mode;

  const _Preview({required this.mode});

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      ThemeMode.light => const _Page(isDark: false),
      ThemeMode.dark => const _Page(isDark: true),
      // Split down the middle, which is the one honest way to draw "whatever
      // the phone is doing": System is not a third appearance, it is a promise
      // to be one of the other two.
      ThemeMode.system => const Row(
        children: <Widget>[
          Expanded(child: _Page(isDark: false)),
          Expanded(child: _Page(isDark: true)),
        ],
      ),
    };
  }
}

class _Page extends StatelessWidget {
  final bool isDark;

  const _Page({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Straight out of the palette, so these cannot drift from the modes they
    // advertise — the canvases are `AppPalette.canvasLight` and `canvasDark`
    // themselves, not approximations of them.
    final AppPalette palette = isDark ? AppPalette.dark : AppPalette.light;

    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 11.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _Bar(color: palette.textPrimary, widthFactor: 0.72, height: 6.h),
            SizedBox(height: 6.h),
            _Bar(color: palette.textSecondary, widthFactor: 0.95, height: 4.h),
            SizedBox(height: 4.h),
            _Bar(color: palette.textSecondary, widthFactor: 0.55, height: 4.h),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final Color color;
  final double widthFactor;
  final double height;

  const _Bar({
    required this.color,
    required this.widthFactor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
