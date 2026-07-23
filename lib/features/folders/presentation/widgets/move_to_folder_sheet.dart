import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';

Future<void> showMoveToFolderSheet(
  BuildContext context, {
  required void Function(int? folderId) onSelected,
  String title = 'Move to folder',
  String noFolderLabel = 'Remove from folder',
  bool showNoFolderOption = true,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => _MoveToFolderSheetContent(
      onSelected: onSelected,
      title: title,
      noFolderLabel: noFolderLabel,
      showNoFolderOption: showNoFolderOption,
    ),
  );
}

class _MoveToFolderSheetContent extends StatefulWidget {
  final void Function(int? folderId) onSelected;
  final String title;
  final String noFolderLabel;
  final bool showNoFolderOption;

  const _MoveToFolderSheetContent({
    required this.onSelected,
    required this.title,
    required this.noFolderLabel,
    required this.showNoFolderOption,
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
                leading: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                title: Text(widget.noFolderLabel, style: AppTextStyles.bodyLarge),
                onTap: () {
                  widget.onSelected(null);
                  Navigator.of(context).pop();
                },
              ),
            FutureBuilder<List<FolderEntity>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                final List<FolderEntity> folders = snapshot.data ?? [];
                if (folders.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      'No folders yet. Create one from the Folders tab.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: folders
                      .map(
                        (folder) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.folder_rounded,
                            color: Color(folder.color),
                          ),
                          title: Text(folder.name, style: AppTextStyles.bodyLarge),
                          onTap: () {
                            widget.onSelected(folder.id);
                            Navigator.of(context).pop();
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
