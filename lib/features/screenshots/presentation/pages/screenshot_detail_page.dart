import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

class ScreenshotDetailPage extends StatefulWidget {
  final List<ScreenshotEntity> screenshots;
  final int initialIndex;

  const ScreenshotDetailPage({
    super.key,
    required this.screenshots,
    required this.initialIndex,
  });

  @override
  State<ScreenshotDetailPage> createState() => _ScreenshotDetailPageState();
}

class _ScreenshotDetailPageState extends State<ScreenshotDetailPage> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share(ScreenshotEntity item) async {
    final File? file = await item.asset.file;
    if (file == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Future<void> _delete(BuildContext context, ScreenshotEntity item) async {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Delete screenshot?',
      message: 'This will permanently delete it from your device.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) bloc.add(DeleteScreenshotEvent(item.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScreenshotsBloc, ScreenshotsState>(
      listener: (context, state) {
        if (state is ScreenshotsLoadedState &&
            state.visibleScreenshots.isEmpty) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final List<ScreenshotEntity> items = state is ScreenshotsLoadedState
            ? state.visibleScreenshots
            : widget.screenshots;
        if (items.isEmpty) return const SizedBox.shrink();

        final int safeIndex = _currentIndex.clamp(0, items.length - 1);
        final ScreenshotEntity current = items[safeIndex];

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  current.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: current.isFavorite ? AppColors.error : Colors.white,
                ),
                onPressed: () => context.read<ScreenshotsBloc>().add(
                  ToggleFavoriteEvent(current.id),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                onPressed: () => _share(current),
              ),
              IconButton(
                icon: const Icon(
                  Icons.drive_file_move_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
                  showMoveToFolderSheet(
                    context,
                    onSelected: (folderId) => bloc.add(
                      MoveScreenshotToFolderEvent(current.id, folderId),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _delete(context, current),
              ),
            ],
          ),
          body: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: FutureBuilder<File?>(
                    future: items[index].asset.file,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator(
                          color: AppColors.primary,
                        );
                      }
                      return Image.file(snapshot.data!, fit: BoxFit.contain);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
