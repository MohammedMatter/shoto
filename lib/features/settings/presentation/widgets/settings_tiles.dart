import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/cache_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_switch.dart';
import 'package:shoto/core/widgets/pro_badge.dart';

/// A row whose control is too wide to sit beside its label — a segmented
/// picker rather than a switch or a chevron.
///
/// Naming these ("Theme", "Grid density") rather than letting a bare row of
/// pills float under a heading matters more than it looks: a control with no
/// label is only obvious to whoever built it.
class SettingsControlRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget control;

  const SettingsControlRow({
    super.key,
    required this.icon,
    required this.label,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(15.w, 14.h, 15.w, 15.h),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 19.sp),
              SizedBox(width: 14.w),
              Text(label, style: AppTextStyles.bodyLarge),
            ],
          ),
          SizedBox(height: 12.h),
          control,
        ],
      ),
    );
  }
}

/// The cache row, which has to measure before it can label itself.
class SettingsClearCacheTile extends StatefulWidget {
  const SettingsClearCacheTile({super.key});

  @override
  State<SettingsClearCacheTile> createState() => _SettingsClearCacheTileState();
}

class _SettingsClearCacheTileState extends State<SettingsClearCacheTile> {
  late Future<int> _sizeFuture = sl<CacheService>().getCacheSizeBytes();

  Future<void> _clear() async {
    await sl<CacheService>().clearCache();
    if (!mounted) return;
    // Block body, not an arrow: an arrow returns the assigned value, which
    // here is a Future, and Flutter asserts that a setState callback never
    // returns one. Same mistake that used to crash the Upgrade button.
    setState(() {
      _sizeFuture = sl<CacheService>().getCacheSizeBytes();
    });
  }

  /// A size, wrapped so it survives being dropped into an Arabic sentence.
  ///
  /// Without the isolate this renders **"MB 6.1"** on an RTL screen, which is
  /// not a size. The reason is the bidi algorithm and not the translation: in
  /// an RTL paragraph, `6.1` resolves as a weak left-to-right number and `MB`
  /// as strong left-to-right text, and the neutral space between them takes
  /// the *paragraph's* direction rather than theirs. That splits one value
  /// into two runs and lays them out right to left.
  ///
  /// U+2066 (left-to-right isolate) and U+2069 (pop directional isolate) fence
  /// the whole thing off as one left-to-right run, so the number keeps its
  /// unit and the Arabic around it keeps its own direction. Any measurement
  /// with a unit needs this — see also the format strings in `app_ar.arb`.
  String _format(int bytes) {
    final String value;
    if (bytes < 1024) {
      value = '$bytes B';
    } else if (bytes < 1024 * 1024) {
      value = '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      value = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '\u2066$value\u2069';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _sizeFuture,
      builder: (context, snapshot) {
        final int bytes = snapshot.data ?? 0;
        return SettingsNavTile(
          icon: Icons.cleaning_services_rounded,
          label: context.l10n.settingsClearCache,
          description: snapshot.hasData
              ? context.l10n.settingsCacheSize(_format(bytes))
              : context.l10n.settingsCacheMeasuring,
          onTap: bytes == 0 ? null : _clear,
        );
      },
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;
  final bool isDestructive;

  /// Whether to mark this row with the PRO tag.
  ///
  /// Named for what it *does* rather than for what the feature is, because the
  /// answer is not a property of the row: it is "this is a paid feature **and**
  /// you have not paid yet". A subscriber's own settings page labelling the
  /// things they just bought as locked is the bug this spells out.
  ///
  /// Decided by the page and passed down, deliberately. Having the row work it
  /// out for itself meant every tile reaching into the service locator for
  /// [ProStatus], which turned a plain presentational widget into one that
  /// could not be built in a widget test at all.
  final bool showProBadge;

  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.isDestructive = false,
    this.showProBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = isDestructive
        ? AppColors.error
        : onTap == null
        ? AppColors.textDisabled
        : AppColors.textPrimary;

    return PressableScale(
      // A tint, not a shrink. This row is full-bleed inside a scrolling page,
      // and a full-width row that scales makes the whole page look like it
      // shuddered every time a finger rests on it before dragging. See
      // PressFeedback.
      feedback: PressFeedback.highlight,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
        // No background or border of its own: the row lives inside a
        // [SettingsGroup] card, which draws both once for the whole group.
        color: AppColors.surface,
        child: Row(
          children: [
            Icon(icon, color: tint, size: 19.sp),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(color: tint),
                  ),
                  SizedBox(height: 1.h),
                  Text(description, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (showProBadge) ...[const ProBadge(), SizedBox(width: 8.w)],
            if (onTap != null && !isDestructive)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(15.w, 8.h, 10.w, 8.h),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 19.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge),
                SizedBox(height: 1.h),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
