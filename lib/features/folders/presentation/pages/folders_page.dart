import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/pages/folder_detail_page.dart';
import 'package:shoto/features/folders/presentation/widgets/create_folder_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Folders', style: AppTextStyles.headlineLarge),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => _createFolder(context),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: BlocBuilder<FoldersBloc, FoldersState>(
                  builder: (context, state) {
                    if (state is FoldersLoadingState ||
                        state is FoldersInitialState) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (state is FoldersErrorState) {
                      return EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Something went wrong',
                        message: state.message,
                      );
                    }

                    final List<FolderEntity> folders =
                        (state as FoldersLoadedState).folders;
                    if (folders.isEmpty) {
                      return EmptyState(
                        icon: Icons.folder_off_rounded,
                        title: 'No folders yet',
                        message:
                            'Create folders to keep your screenshots organized.',
                        action: PrimaryButton(
                          label: 'New Folder',
                          onPressed: () => _createFolder(context),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.only(bottom: 120.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14.h,
                        crossAxisSpacing: 14.w,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final FolderEntity folder = folders[index];
                        return FolderCard(
                          folder: folder,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FolderDetailPage(folder: folder),
                            ),
                          ),
                          onLongPress: () =>
                              _showFolderActions(context, folder),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createFolder(BuildContext context) {
    final FoldersBloc bloc = context.read<FoldersBloc>();
    showCreateFolderSheet(
      context,
      onCreate: (name, color) => bloc.add(CreateFolderEvent(name, color)),
    );
  }

  void _showFolderActions(BuildContext context, FolderEntity folder) {
    final FoldersBloc bloc = context.read<FoldersBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: AppColors.textPrimary,
              ),
              title: Text('Rename', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _renameFolder(context, bloc, folder);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Delete',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final bool confirmed = await showConfirmDialog(
                  context,
                  title: 'Delete "${folder.name}"?',
                  message: 'Screenshots inside will stay in your library.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirmed) bloc.add(DeleteFolderEvent(folder.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameFolder(
    BuildContext context,
    FoldersBloc bloc,
    FolderEntity folder,
  ) {
    final TextEditingController controller = TextEditingController(
      text: folder.name,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Folder', style: AppTextStyles.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final String name = controller.text.trim();
              if (name.isNotEmpty) {
                bloc.add(RenameFolderEvent(folder.id, name));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Save',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
