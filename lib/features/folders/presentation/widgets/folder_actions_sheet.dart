import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_editor_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_mark.dart';

/// Edit / delete actions for a folder.
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
                  // The folder as it looks everywhere else, not a generic
                  // glyph. This header exists to confirm *which* folder is
                  // about to be edited or deleted, and the grid it was opened
                  // from is telling them apart by colour and picture.
                  FolderMark(folder: folder, size: 30.w),
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
                context.l10n.foldersEditTitle,
                style: context.text.bodyLarge,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                // The sheet that made the folder, opened on the folder. It was
                // a dialog holding one text field, which is why the glyph and
                // the colour could be chosen once and never corrected.
                showFolderEditorSheet(
                  context,
                  existing: folder,
                  onSave: (name, color, iconKey, _) {
                    bloc.add(
                      UpdateFolderEvent(
                        folder.id,
                        name: name,
                        color: color,
                        iconKey: iconKey,
                      ),
                    );
                    // Fired on every save rather than only when the text
                    // changed. The detail page uses it to retitle itself, and
                    // handing it the name unconditionally is both simpler and
                    // correct — re-titling to the same string costs a rebuild
                    // of one `Text`.
                    onRenamed?.call(name);
                  },
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
