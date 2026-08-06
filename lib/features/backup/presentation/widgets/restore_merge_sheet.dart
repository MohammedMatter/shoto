import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/backup/domain/entities/restore_plan.dart';

/// Asks what to do about folders in the backup whose names are already taken.
///
/// **The app refuses to decide this one.** Merging is usually right and
/// occasionally destructive: two different folders can genuinely share a name,
/// and pouring one into the other puts unrelated screenshots together in a way
/// nobody notices until they go looking for something. Keeping them apart is
/// safe and occasionally silly — a pile of duplicate names. Neither default is
/// good enough to apply silently, and the user is the only one who knows which
/// case this is.
///
/// One question for the whole file rather than one per folder: three dialogs
/// asking the same thing is how somebody starts tapping the default without
/// reading it.
Future<FolderMergeChoice?> showRestoreMergeSheet(
  BuildContext context, {
  required List<String> names,
}) {
  return showAppSheet<FolderMergeChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _RestoreMergeSheet(names: names),
  );
}

class _RestoreMergeSheet extends StatelessWidget {
  final List<String> names;

  const _RestoreMergeSheet({required this.names});

  @override
  Widget build(BuildContext context) {
    // Duplicated names inside the backup itself would otherwise be listed
    // twice, which reads as the app having miscounted.
    final List<String> unique = names.toSet().toList();

    return SheetSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              context.l10n.restoreClashTitle(unique.length),
              style: context.text.headlineMedium,
            ),
            SizedBox(height: 10.h),
            Text(
              context.l10n.restoreClashBody,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),

            // The names themselves, because "3 folders" is not enough to
            // decide on. Whether merging is right depends entirely on which
            // folders they are.
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final String name in unique.take(8))
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 11.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Text(
                      name,
                      style: context.text.caption.asMedium.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                if (unique.length > 8)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text(
                      context.l10n.restoreClashMore(unique.length - 8),
                      style: context.text.caption.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 22.h),

            _Option(
              icon: Icons.merge_rounded,
              tint: context.colors.secondary,
              title: context.l10n.restoreClashMerge,
              body: context.l10n.restoreClashMergeBody,
              onTap: () => Navigator.of(context).pop(FolderMergeChoice.merge),
            ),
            SizedBox(height: 10.h),
            _Option(
              icon: Icons.call_split_rounded,
              tint: context.colors.primary,
              title: context.l10n.restoreClashSeparate,
              body: context.l10n.restoreClashSeparateBody,
              onTap: () =>
                  Navigator.of(context).pop(FolderMergeChoice.keepSeparate),
            ),
          ],
        ),
      ),
    );
  }
}

/// Both choices are given equal visual weight on purpose — one of them is not
/// a "cancel", and styling either as secondary would be the app making the
/// decision it just said it would not make.
class _Option extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: tint, size: 17.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.bodyLarge.asMedium),
                  SizedBox(height: 3.h),
                  Text(
                    body,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
