import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';

/// Picking the order the library is shown in.
///
/// **This replaced a bare arrow in the header, and it replaced it because the
/// arrow did not work.** A single glyph that flipped between ↓ and ↑ was
/// unreadable on two counts: nothing said it was about *order* rather than
/// filtering or downloading, and nothing said which order was on — an arrow
/// pointing down is equally believable as "newest at the top" and as "tap to
/// go oldest". The tooltip that was supposed to cover this needs a long-press
/// on Android, so in practice it did not exist.
///
/// Two named rows with a tick against the current one answer both questions
/// before the user commits to anything, which a toggle by definition cannot.
Future<void> showLibrarySortSheet(
  BuildContext context, {
  required LibrarySort current,
  required ValueChanged<LibrarySort> onSelected,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => SheetSurface(
      child: _LibrarySortSheet(current: current, onSelected: onSelected),
    ),
  );
}

class _LibrarySortSheet extends StatelessWidget {
  final LibrarySort current;
  final ValueChanged<LibrarySort> onSelected;

  const _LibrarySortSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.librarySortLabel,
              style: AppTextStyles.headlineMedium,
            ),
            SizedBox(height: 12.h),
            for (final LibrarySort sort in LibrarySort.values)
              _SortRow(
                sort: sort,
                isCurrent: sort == current,
                onTap: () {
                  // Popped first so the sheet is already on its way out while
                  // the grid re-orders behind it, rather than the user
                  // watching a dismissed sheet sit there through the work.
                  Navigator.of(context).pop();
                  if (sort != current) onSelected(sort);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  final LibrarySort sort;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SortRow({
    required this.sort,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String label = switch (sort) {
      LibrarySort.newest => context.l10n.librarySortNewest,
      LibrarySort.oldest => context.l10n.librarySortOldest,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        // The arrows survive, but only beside the words that explain them.
        sort.isNewestFirst ? Icons.south_rounded : Icons.north_rounded,
        color: isCurrent ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.weight(
          isCurrent ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
