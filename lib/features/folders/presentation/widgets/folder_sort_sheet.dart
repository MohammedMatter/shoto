import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';

/// Picking the order the folder grid is shown in.
///
/// **Named rows with a tick, never an arrow in the header** — and that shape
/// is inherited rather than invented here. The Library wore the arrow first,
/// and it did not work on two counts: nothing said the glyph was about *order*
/// rather than filtering or downloading, and nothing said which order was
/// currently on, because a downward arrow is equally believable as "newest at
/// the top" and as "tap to go oldest". The tooltip meant to cover that needs a
/// long-press on Android, so in practice it did not exist.
///
/// Two named rows with a tick against the current one answer both questions
/// before the user commits to anything, which a toggle by definition cannot.
///
/// The reasoning used to live in `library_sort_sheet.dart` and is written out
/// here because that file is gone: the Library's ordering moved into the
/// "Order" section of [showLibraryViewSheet], which follows the same rule, and
/// the sheet it left behind sat unreferenced for long enough that an audit had
/// to find it. This is now the only copy.
Future<void> showFolderSortSheet(
  BuildContext context, {
  required FolderSort current,
  required ValueChanged<FolderSort> onSelected,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => SheetSurface(
      child: _FolderSortSheet(current: current, onSelected: onSelected),
    ),
  );
}

class _FolderSortSheet extends StatelessWidget {
  final FolderSort current;
  final ValueChanged<FolderSort> onSelected;

  const _FolderSortSheet({required this.current, required this.onSelected});

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
              context.l10n.foldersSortLabel,
              style: context.text.headlineMedium,
            ),
            SizedBox(height: 12.h),
            for (final FolderSort sort in FolderSort.values)
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
  final FolderSort sort;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SortRow({
    required this.sort,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (String label, IconData icon) = switch (sort) {
      FolderSort.recent => (
        context.l10n.foldersSortRecent,
        Icons.schedule_rounded,
      ),
      FolderSort.name => (
        context.l10n.foldersSortName,
        Icons.sort_by_alpha_rounded,
      ),
      FolderSort.fullest => (
        context.l10n.foldersSortFullest,
        Icons.filter_none_rounded,
      ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isCurrent
            ? context.colors.primary
            : context.colors.textSecondary,
      ),
      title: Text(
        label,
        style: context.text.bodyLarge.weight(
          isCurrent ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check_rounded, color: context.colors.primary)
          : null,
      onTap: onTap,
    );
  }
}
