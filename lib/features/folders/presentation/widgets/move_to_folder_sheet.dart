import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';

Future<void> showMoveToFolderSheet(
  BuildContext context, {
  required void Function(int? folderId) onSelected,
  // Nullable rather than defaulted: the fallback is a translated string,
  // which is only knowable once there is a context to read it from.
  String? title,
  String? noFolderLabel,
  bool showNoFolderOption = true,
  int? currentFolderId,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SheetSurface(
      child: _MoveToFolderSheetContent(
        onSelected: onSelected,
        title: title ?? context.l10n.foldersMoveTitle,
        noFolderLabel: noFolderLabel ?? context.l10n.foldersMoveRemove,
        showNoFolderOption: showNoFolderOption,
        currentFolderId: currentFolderId,
      ),
    ),
  );
}

class _MoveToFolderSheetContent extends StatefulWidget {
  final void Function(int? folderId) onSelected;
  final String title;
  final String noFolderLabel;
  final bool showNoFolderOption;
  final int? currentFolderId;

  const _MoveToFolderSheetContent({
    required this.onSelected,
    required this.title,
    required this.noFolderLabel,
    required this.showNoFolderOption,
    required this.currentFolderId,
  });

  @override
  State<_MoveToFolderSheetContent> createState() =>
      _MoveToFolderSheetContentState();
}

class _MoveToFolderSheetContentState extends State<_MoveToFolderSheetContent> {
  late final Future<List<FolderEntity>> _future = sl<GetFoldersUseCase>()();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        // Without a ceiling the sheet grows with the folder list and simply
        // runs off the bottom of the screen — which is what the yellow
        // overflow stripe was reporting once the library had a dozen folders.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppTextStyles.headlineMedium),
              SizedBox(height: 12.h),
              if (widget.showNoFolderOption)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: widget.currentFolderId == null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    widget.noFolderLabel,
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: widget.currentFolderId == null
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    widget.onSelected(null);
                    Navigator.of(context).pop();
                  },
                ),
              // Flexible + a scroll view: the title and the "no folder" row
              // stay put while only the list moves, which is what a picker
              // should do — and it can now hold any number of folders.
              Flexible(
                child: SingleChildScrollView(
                  child: FutureBuilder<List<FolderEntity>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      final List<FolderEntity> folders = snapshot.data ?? [];
                      if (folders.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Text(
                            context.l10n.foldersMoveNone,
                            style: AppTextStyles.bodyMedium,
                          ),
                        );
                      }
                      return Column(
                        children: folders.map((folder) {
                          final bool isCurrent =
                              folder.id == widget.currentFolderId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.folder_rounded,
                              color: Color(folder.color),
                            ),
                            title: Text(
                              folder.name,
                              style: AppTextStyles.bodyLarge.weight(
                                isCurrent
                                    ? AppTextStyles.semiBold
                                    : AppTextStyles.regular,
                              ),
                            ),
                            trailing: isCurrent
                                ? Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () {
                              widget.onSelected(folder.id);
                              Navigator.of(context).pop();
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
