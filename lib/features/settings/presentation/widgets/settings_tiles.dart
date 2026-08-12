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

/// A row whose control is a segmented picker rather than a switch or a chevron.
///
/// Naming these ("Theme", "Grid density") rather than letting a bare row of
/// pills float under a heading matters more than it looks: a control with no
/// label is only obvious to whoever built it.
///
/// **The picker sits beside the label, not under it**, and that is worth the
/// note because it used to be the other way round. A full-width segmented
/// control with a caption under every glyph is a good way to introduce three
/// options nobody has met before — and there are exactly two of these rows,
/// both at the top of the page, so between them they were taking about a third
/// of the screen to hold two preferences most people set once and never open
/// again. Everything else in Settings was below the fold because of it.
///
/// Compact mode drops the captions and lets the pill size to its own glyphs, so
/// the row becomes what it always was: a label, and the answer on the other
/// end — the same shape as every switch row above and below it. See
/// [ThemeModeSelector.compact].
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: context.colors.textPrimary, size: 19.sp),
          SizedBox(width: 14.w),
          // Takes the slack so the pill is pinned to the trailing edge and the
          // two rows line their controls up with each other — and with the
          // switches in the group below.
          Expanded(child: Text(label, style: context.text.bodyLarge)),
          SizedBox(width: 12.w),
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
          icon: Icons.cleaning_services_outlined,
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
        ? context.colors.error
        : onTap == null
        ? context.colors.textDisabled
        : context.colors.textPrimary;

    return PressableScale(
      // A tint, not a shrink. This row is full-bleed inside a scrolling page,
      // and a full-width row that scales makes the whole page look like it
      // shuddered every time a finger rests on it before dragging. See
      // PressFeedback.
      feedback: PressFeedback.highlight,
      onTap: onTap,
      child: Container(
        // **No padding on the sides and no surface of its own.** The group's
        // card is gone, so the row aligns to the page gutter like the heading
        // above it rather than being inset from a container that no longer
        // exists — and it paints nothing, so the canvas shows through.
        padding: EdgeInsets.symmetric(vertical: 14.h),
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
                    style: context.text.bodyLarge.copyWith(color: tint),
                  ),
                  SizedBox(height: 1.h),
                  Text(description, style: context.text.caption),
                ],
              ),
            ),
            if (showProBadge) ...[const ProBadge(), SizedBox(width: 8.w)],
            if (onTap != null && !isDestructive)
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textDisabled,
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
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: context.colors.textPrimary, size: 19.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodyLarge),
                SizedBox(height: 1.h),
                Text(description, style: context.text.caption),
              ],
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
