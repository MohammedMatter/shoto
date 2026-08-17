import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_icon.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// The six launcher icons, drawn by the painter that generates them.
///
/// **Not the PNGs.** The obvious way to build this row is to show
/// `mipmap/ic_launcher_<id>`, and it is wrong twice over: those files are
/// Android-only resources that Flutter cannot address, and even where it could,
/// the row would then be six pictures that could silently fall out of step with
/// the icon actually installed. Drawing them here from
/// [ShotoBrandMarkPainter] — the same painter
/// `tool/generate_brand_assets.dart` renders the real files with — means the
/// preview and the icon are the same drawing by construction.
///
/// The corner radius is Shoto's own rather than the launcher's, because the
/// launcher's is unknowable: the device's icon mask is a user setting, and
/// guessing at a squircle here would be wrong on most phones. A rounded square
/// says "this is the icon" without claiming to know how it will be cut.
class AppIconPicker extends StatelessWidget {
  final AppIcon value;

  /// Returns whether the icon actually changed — the swap can be refused by a
  /// paywall or fail on the platform, and this row must not light a ring for
  /// something that did not happen.
  final Future<bool> Function(AppIcon) onSelect;

  /// Greys the row while a swap is in flight. The call is a package-manager
  /// write and takes long enough to see; two overlapping swaps would each
  /// disable what the other enabled.
  final bool isBusy;

  const AppIconPicker({
    super.key,
    required this.value,
    required this.onSelect,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92.h,
      child: IgnorePointer(
        ignoring: isBusy,
        child: AnimatedOpacity(
          opacity: isBusy ? 0.5 : 1,
          duration: AppMotion.duration(context, AppMotion.normal),
          curve: AppMotion.standard,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            itemCount: AppIcon.all.length,
            separatorBuilder: (_, _) => SizedBox(width: 12.w),
            itemBuilder: (BuildContext context, int index) {
              final AppIcon icon = AppIcon.all[index];
              return _IconTile(
                icon: icon,
                isSelected: icon == value,
                onTap: () => onSelect(icon),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final AppIcon icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconTile({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  static double get _size => 54;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.93,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The ring lives in a box that is always present, so choosing an
          // icon never resizes the tile or shifts the five beside it.
          AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: _size.w,
                height: _size.w,
                child: CustomPaint(
                  painter: ShotoBrandMarkPainter(
                    markExtent: _size.w,
                    slab: icon.slab,
                    // Square-cornered, because the ClipRRect above is already
                    // rounding it. A slab that arrives pre-rounded inside a
                    // rounded clip shows a pale seam where the two radii
                    // disagree — the same reason the generator passes zero for
                    // the adaptive background.
                    backdropCornerRadius: 0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            icon.label(context),
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
