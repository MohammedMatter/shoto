import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_dialog.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';

/// Rename / delete actions for a folder.
///
/// Shared between the folders grid and a folder's own detail page so both
/// entry points behave identically. [bloc] is passed explicitly rather than
/// looked up from [context], because the detail page is pushed as its own
/// route and therefore sits outside the provider that owns the grid's bloc.
///
/// [onRenamed] and [onDeleted] let a caller that displays the folder itself
/// (the detail page) react — update its title, or pop, since the thing it
/// was showing no longer exists.
Future<void> showFolderActionsSheet(
  BuildContext context, {
  required FolderEntity folder,
  required FoldersBloc bloc,
  ValueChanged<String>? onRenamed,
  VoidCallback? onDeleted,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => SheetSurface(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: Color(folder.color),
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: context.text.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: context.colors.textPrimary,
              ),
              title: Text(
                context.l10n.commonRename,
                style: context.text.bodyLarge,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _promptRename(
                  context,
                  folder: folder,
                  bloc: bloc,
                  onRenamed: onRenamed,
                );
              },
            ),
            ListTile(
              // Not const, and it cannot be: `error` is read from the theme,
              // so it resolves at build time rather than compile time.
              leading: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.error,
              ),
              title: Text(
                context.l10n.foldersDelete,
                style: context.text.bodyLarge.copyWith(
                  color: context.colors.error,
                ),
              ),
              subtitle: Text(
                context.l10n.foldersDeleteKept,
                style: context.text.caption,
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final bool confirmed = await showConfirmDialog(
                  context,
                  title: context.l10n.foldersDeleteTitle(folder.name),
                  message: context.l10n.foldersDeleteMessage,
                  confirmLabel: context.l10n.commonDelete,
                  isDestructive: true,
                );
                if (!confirmed) return;
                bloc.add(DeleteFolderEvent(folder.id));
                onDeleted?.call();
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

void _promptRename(
  BuildContext context, {
  required FolderEntity folder,
  required FoldersBloc bloc,
  ValueChanged<String>? onRenamed,
}) {
  final TextEditingController controller = TextEditingController(
    text: folder.name,
  );

  showAppDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.foldersRenameTitle,
        style: context.text.titleLarge,
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: context.text.bodyLarge,
        decoration: InputDecoration(
          filled: true,
          fillColor: context.colors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            context.l10n.commonCancel,
            style: context.text.button.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final String name = controller.text.trim();
            Navigator.of(dialogContext).pop();
            if (name.isEmpty || name == folder.name) return;
            bloc.add(RenameFolderEvent(folder.id, name));
            onRenamed?.call(name);
          },
          child: Text(
            context.l10n.commonSave,
            style: context.text.button.copyWith(color: context.colors.primary),
          ),
        ),
      ],
    ),
  );
}
