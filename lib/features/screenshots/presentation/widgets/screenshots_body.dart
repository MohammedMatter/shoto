import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';

/// Shared body for any screen that lists screenshots from a
/// [ScreenshotsBloc] already available above it in the widget tree — used by
/// both the Home tab (all screenshots) and a folder's detail page (scoped).
class ScreenshotsBody extends StatelessWidget {
  final String emptyTitle;
  final String emptyMessage;
  final bool showFavoritesFilter;

  const ScreenshotsBody({
    super.key,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showFavoritesFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      builder: (context, state) {
        if (state is ScreenshotsLoadingState ||
            state is ScreenshotsInitialState) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ScreenshotsPermissionDeniedState) {
          return EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Photo access needed',
            message:
                'Allow SHOTO to access your photos so it can find your screenshots.',
            action: PrimaryButton(
              label: 'Open Settings',
              onPressed: () => PhotoManager.openSetting(),
            ),
          );
        }

        if (state is ScreenshotsErrorState) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            message: state.message,
            action: PrimaryButton(
              label: 'Try Again',
              onPressed: () =>
                  context.read<ScreenshotsBloc>().add(LoadScreenshotsEvent()),
            ),
          );
        }

        final ScreenshotsLoadedState loaded = state as ScreenshotsLoadedState;
        final items = loaded.visibleScreenshots;

        return Column(
          children: [
            if (loaded.isSelectionMode)
              _SelectionToolbar(count: loaded.selectedIds.length)
            else if (showFavoritesFilter)
              _FavoritesFilterRow(favoritesOnly: loaded.favoritesOnly),
            Expanded(
              child: items.isEmpty
                  ? EmptyState(
                      icon: Icons.image_search_rounded,
                      title: loaded.favoritesOnly
                          ? 'No favorites yet'
                          : emptyTitle,
                      message: loaded.favoritesOnly
                          ? 'Tap the heart on a screenshot to save it here.'
                          : emptyMessage,
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async => context
                          .read<ScreenshotsBloc>()
                          .add(RefreshScreenshotsEvent()),
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 120.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10.h,
                          crossAxisSpacing: 10.w,
                          childAspectRatio: 1,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ScreenshotThumbnail(
                            asset: item.asset,
                            isFavorite: item.isFavorite,
                            isSelected: loaded.selectedIds.contains(item.id),
                            selectionMode: loaded.isSelectionMode,
                            onTap: () {
                              if (loaded.isSelectionMode) {
                                context.read<ScreenshotsBloc>().add(
                                  ToggleSelectItemEvent(item.id),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<ScreenshotsBloc>(),
                                      child: ScreenshotDetailPage(
                                        screenshots: items,
                                        initialIndex: index,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () => context
                                .read<ScreenshotsBloc>()
                                .add(ToggleSelectItemEvent(item.id)),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  final int count;
  const _SelectionToolbar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 12.w, 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.read<ScreenshotsBloc>().add(ClearSelectionEvent()),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 12.w),
          Text('$count selected', style: AppTextStyles.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.drive_file_move_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
              showMoveToFolderSheet(
                context,
                onSelected: (folderId) =>
                    bloc.add(MoveSelectedToFolderEvent(folderId)),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () async {
              final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
              final bool confirmed = await showConfirmDialog(
                context,
                title: 'Delete screenshots?',
                message:
                    'This will permanently delete $count screenshot${count == 1 ? '' : 's'} from your device.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed) bloc.add(DeleteSelectedEvent());
            },
          ),
        ],
      ),
    );
  }
}

class _FavoritesFilterRow extends StatelessWidget {
  final bool favoritesOnly;
  const _FavoritesFilterRow({required this.favoritesOnly});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () =>
              context.read<ScreenshotsBloc>().add(ToggleFavoritesFilterEvent()),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: favoritesOnly ? null : AppColors.surface,
              gradient: favoritesOnly ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 15.sp,
                  color: favoritesOnly ? Colors.white : AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Favorites',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: favoritesOnly
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
