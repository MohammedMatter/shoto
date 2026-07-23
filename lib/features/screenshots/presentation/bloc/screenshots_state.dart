import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

class ScreenshotsState {}

class ScreenshotsInitialState extends ScreenshotsState {}

class ScreenshotsLoadingState extends ScreenshotsState {}

class ScreenshotsPermissionDeniedState extends ScreenshotsState {}

class ScreenshotsErrorState extends ScreenshotsState {
  final String message;
  ScreenshotsErrorState(this.message);
}

class ScreenshotsLoadedState extends ScreenshotsState {
  final List<ScreenshotEntity> screenshots;
  final Set<String> selectedIds;
  final bool favoritesOnly;

  ScreenshotsLoadedState({
    required this.screenshots,
    this.selectedIds = const {},
    this.favoritesOnly = false,
  });

  bool get isSelectionMode => selectedIds.isNotEmpty;

  List<ScreenshotEntity> get visibleScreenshots => favoritesOnly
      ? screenshots.where((s) => s.isFavorite).toList()
      : screenshots;

  ScreenshotsLoadedState copyWith({
    List<ScreenshotEntity>? screenshots,
    Set<String>? selectedIds,
    bool? favoritesOnly,
  }) {
    return ScreenshotsLoadedState(
      screenshots: screenshots ?? this.screenshots,
      selectedIds: selectedIds ?? this.selectedIds,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}
