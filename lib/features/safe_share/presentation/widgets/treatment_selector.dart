import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';

/// What to do about one finding: cover it, or leave it.
///
/// Two visible states rather than a switch. The whole screen exists so that
/// nobody sends a screenshot believing something was handled when it was not,
/// and a control that has to be opened to be read works against that — you
/// should be able to run an eye down the list and see, for every line,
/// exactly what will happen.
class TreatmentSelector extends StatelessWidget {
  final RegionTreatment value;
  final ValueChanged<RegionTreatment> onChanged;

  const TreatmentSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Option(
            label: context.l10n.safeShareTreatmentCover,
            icon: Icons.square_rounded,
            selected: value == RegionTreatment.cover,
            onTap: () => onChanged(RegionTreatment.cover),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _Option(
            label: context.l10n.safeShareTreatmentKeep,
            icon: Icons.visibility_outlined,
            selected: value == RegionTreatment.keep,
            // The one option that leaves a real value in the picture, so it
            // is the one coloured as a warning when it is chosen.
            danger: true,
            onTap: () => onChanged(RegionTreatment.keep),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = danger ? context.colors.error : context.colors.primary;
    final Color foreground = selected
        ? (danger ? context.colors.error : context.colors.onPrimary)
        : context.colors.textSecondary;

    return PressableScale(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.press),
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: selected
              ? (danger ? accent.withValues(alpha: 0.14) : accent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(
            color: selected
                ? (danger ? accent.withValues(alpha: 0.55) : accent)
                : context.colors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: foreground),
            SizedBox(height: 2.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.caption.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
