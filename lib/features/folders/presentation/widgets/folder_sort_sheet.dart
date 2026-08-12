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
/// Built to the same shape as `showLibrarySortSheet`, and the reasoning
/// recorded there applies unchanged: named rows with a tick against the
/// current one, rather than a glyph in the header that flips between two
/// states and tells you neither which axis it is about nor which way it is
/// currently pointing.
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
