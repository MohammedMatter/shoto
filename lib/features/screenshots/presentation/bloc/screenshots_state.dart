import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';

class ScreenshotsState {}

class ScreenshotsInitialState extends ScreenshotsState {}

class ScreenshotsLoadingState extends ScreenshotsState {}

class ScreenshotsPermissionDeniedState extends ScreenshotsState {
  /// True when the OS granted *partial* photo access ("Select photos…").
  ///
  /// Treated as blocked rather than allowed on purpose: partial access only
  /// exposes the handful of images the user hand-picked, so the Screenshots
  /// album this app is built around isn't visible at all and the library
  /// would silently come back empty. The UI says so explicitly instead of
  /// showing a confusing "no screenshots" screen.
  final bool isPartialAccess;

  ScreenshotsPermissionDeniedState({this.isPartialAccess = false});
}

class ScreenshotsErrorState extends ScreenshotsState {
  final AppMessage message;
  ScreenshotsErrorState(this.message);
}

class ScreenshotsLoadedState extends ScreenshotsState {
  final List<ScreenshotEntity> screenshots;
  final Set<String> selectedIds;
  final LibraryFilter filter;

  /// The job the user came here to do, when another screen sent them.
  final LibraryIntent intent;

  ScreenshotsLoadedState({
    required this.screenshots,
    this.selectedIds = const {},
    this.filter = LibraryFilter.all,
    this.intent = LibraryIntent.none,
  });

  /// **Selection mode is no longer the same thing as "something is
  /// selected".**
  ///
  /// It used to be exactly `selectedIds.isNotEmpty`, which is true for
  /// selection the user starts themselves — a long-press both enters the mode
  /// and picks the first tile, so the two can never disagree. It cannot
  /// describe a selection somebody else started: Home tapping "Merge" has to
  /// leave the Library *waiting* for a choice, and with nothing picked yet
  /// there was no way to say so.
  bool get isSelectionMode => selectedIds.isNotEmpty || intent.isGuided;

  /// Whether the guiding prompt still has something to ask for.
  ///
  /// Merging needs two, protecting needs exactly one — so the prompt is not
  /// simply "until you pick something", it is "until you have picked enough".
  bool get intentUnsatisfied => switch (intent) {
    LibraryIntent.none => false,
    LibraryIntent.merge => selectedIds.length < 2,
    LibraryIntent.protect => selectedIds.length != 1,
  };

  /// What the grid actually draws. [screenshots] stays the whole library so
  /// the filter pills can keep showing every count while one of them is on —
  /// a filter that hid its own alternatives' totals would be a dead end.
  List<ScreenshotEntity> get visibleScreenshots => switch (filter) {
    LibraryFilter.all => screenshots,
    LibraryFilter.unsorted => screenshots.where((s) => s.isUnsorted).toList(),
    LibraryFilter.favorites => screenshots.where((s) => s.isFavorite).toList(),
  };

  int get unsortedCount => screenshots.where((s) => s.isUnsorted).length;

  int get favoritesCount => screenshots.where((s) => s.isFavorite).length;

  ScreenshotsLoadedState copyWith({
    List<ScreenshotEntity>? screenshots,
    Set<String>? selectedIds,
    LibraryFilter? filter,
    LibraryIntent? intent,
  }) {
    return ScreenshotsLoadedState(
      screenshots: screenshots ?? this.screenshots,
      selectedIds: selectedIds ?? this.selectedIds,
      filter: filter ?? this.filter,
      intent: intent ?? this.intent,
    );
  }
}
