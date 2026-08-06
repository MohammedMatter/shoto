import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';

/// Picks the app's language.
///
/// A sheet rather than the segmented pills used for theme and grid density:
/// six options with long names in six different scripts do not fit in a row,
/// and squeezing them there is how you end up with a picker nobody can read
/// the options of.
Future<void> showLanguageSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final LocaleController controller = sl<LocaleController>();

    return SheetSurface(
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 18.h),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(context.l10n.settingsLanguage, style: context.text.titleLarge),
            SizedBox(height: 14.h),

            // "Follow the phone" is a real choice, not the absence of one, so
            // it sits in the list and can be selected back into.
            _Row(
              title: context.l10n.settingsLanguageSystem,
              subtitle: context.l10n.settingsLanguageSystemHint(
                controller.effectiveLanguage.endonym,
              ),
              selected: controller.language == null,
              onTap: () {
                controller.setLanguage(null);
                Navigator.of(context).pop();
              },
            ),
            Divider(color: context.colors.border, height: 20.h),

            for (final AppLanguage language in AppLanguage.values)
              _Row(
                // Its own name, in its own script. Somebody who needs Urdu is
                // looking for اردو, and cannot be expected to find it under a
                // row that says "Urdu" in a language they don't read.
                title: language.endonym,
                subtitle: language.englishName,
                selected: controller.language == language,
                onTap: () {
                  controller.setLanguage(language);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary.withValues(alpha: 0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.bodyLarge),
                  Text(subtitle, style: context.text.caption),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: context.colors.primary,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}
