import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';

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

  /// What each screenshot's cached text turned out to contain.
  ///
  /// **A missing key and an empty set mean different things**, and the whole
  /// feature depends on the distinction. An empty set is "we read this and it
  /// carries no trait"; a missing key is "nobody has ever read this one", which
  /// is most of a fresh library. Reporting the second as the first would let
  /// the header claim a clean library when it has merely never looked — see
  /// [unreadCount].
  final Map<String, Set<ContentTrait>> traits;

  /// The content trait the grid is narrowed to, if any.
  ///
  /// Independent of [filter] on purpose. Status ("have I dealt with this") and
  /// content ("what is in it") are orthogonal questions, so both can be on at
  /// once — unlike the mutually exclusive slices inside [LibraryFilter].
  final ContentTrait? lens;

  /// Whether the background trait pass has finished for this library.
  ///
  /// Deriving traits costs roughly 700µs per screenshot, so it cannot run
  /// inside the load without stalling the grid. Until this is true the trait
  /// controls are not offered at all, because a trait row showing zeroes it
  /// has not finished counting is worse than no trait row.
  final bool traitsReady;

  /// Whether recognition is running over the unread screenshots right now.
  ///
  /// Its own flag rather than a derived one: the scan is the only thing in
  /// this screen the user starts and then waits on, and a control that gives
  /// no sign it was pressed gets pressed again.
  final bool isScanning;

  /// Which end of the library the grid starts from.
  final LibrarySort sort;

  ScreenshotsLoadedState({
    required this.screenshots,
    this.selectedIds = const {},
    this.filter = LibraryFilter.all,
    this.intent = LibraryIntent.none,
    this.traits = const {},
    this.lens,
    this.traitsReady = false,
    this.isScanning = false,
    this.sort = LibrarySort.newest,
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
  ///
  /// Status narrows first, then content. The order is invisible in the result
  /// — set intersection commutes — but it keeps the cheap test first for a
  /// library where most screenshots have no cached text.
  List<ScreenshotEntity> get visibleScreenshots {
    final Iterable<ScreenshotEntity> byStatus = switch (filter) {
      LibraryFilter.all => screenshots,
      LibraryFilter.unsorted => screenshots.where((s) => s.isUnsorted),
      LibraryFilter.favorites => screenshots.where((s) => s.isFavorite),
    };
    final ContentTrait? active = lens;
    final List<ScreenshotEntity> narrowed = active == null
        ? byStatus.toList()
        : byStatus.where((s) => hasTrait(s.id, active)).toList();

    // Sorted last, and always — the repository's order is whatever the gallery
    // handed back, and leaving "newest" to mean "however the OS felt" is how a
    // grid ends up in a different order on two phones with the same library.
    narrowed.sort((a, b) {
      final int byDate = a.asset.createDateTime.compareTo(
        b.asset.createDateTime,
      );
      // Ties broken by id so the order is total. Two screenshots captured in
      // the same second are common — a burst of taps on the shutter — and an
      // unstable comparator makes them swap places on every rebuild.
      final int tie = byDate != 0 ? byDate : a.id.compareTo(b.id);
      return sort.isNewestFirst ? -tie : tie;
    });
    return narrowed;
  }

  bool hasTrait(String assetId, ContentTrait trait) =>
      traits[assetId]?.contains(trait) ?? false;

  int get unsortedCount => screenshots.where((s) => s.isUnsorted).length;

  int get favoritesCount => screenshots.where((s) => s.isFavorite).length;

  /// How many screenshots carry [trait], **within the status slice already
  /// chosen**.
  ///
  /// Scoped rather than library-wide because the two pill groups are read
  /// together: with "Unsorted" lit, a Links pill reading 40 while the grid can
  /// only ever show the 3 unsorted ones is a number that answers no question
  /// the user asked.
  int traitCount(ContentTrait trait) {
    final Iterable<ScreenshotEntity> byStatus = switch (filter) {
      LibraryFilter.all => screenshots,
      LibraryFilter.unsorted => screenshots.where((s) => s.isUnsorted),
      LibraryFilter.favorites => screenshots.where((s) => s.isFavorite),
    };
    return byStatus.where((s) => hasTrait(s.id, trait)).length;
  }

  /// Screenshots whose text has never been recognised, so no trait filter can
  /// see them yet.
  ///
  /// This is the number that keeps the feature honest. Every trait here is
  /// read out of cached OCR text, and text is only cached once some feature
  /// has paid to extract it — so on a library nobody has searched, every trait
  /// count is legitimately zero and *means nothing*. The header says so rather
  /// than letting an empty result imply an absence.
  int get unreadCount =>
      screenshots.where((s) => !traits.containsKey(s.id)).length;

  ScreenshotsLoadedState copyWith({
    List<ScreenshotEntity>? screenshots,
    Set<String>? selectedIds,
    LibraryFilter? filter,
    LibraryIntent? intent,
    Map<String, Set<ContentTrait>>? traits,
    ContentTrait? lens,
    bool clearLens = false,
    bool? traitsReady,
    bool? isScanning,
    LibrarySort? sort,
  }) {
    return ScreenshotsLoadedState(
      screenshots: screenshots ?? this.screenshots,
      selectedIds: selectedIds ?? this.selectedIds,
      filter: filter ?? this.filter,
      intent: intent ?? this.intent,
      traits: traits ?? this.traits,
      // Nullable fields cannot be cleared by passing null — that is
      // indistinguishable from omitting the argument — so turning the lens off
      // needs its own flag, same as `clearFolder` on ScreenshotEntity.
      lens: clearLens ? null : (lens ?? this.lens),
      traitsReady: traitsReady ?? this.traitsReady,
      isScanning: isScanning ?? this.isScanning,
      sort: sort ?? this.sort,
    );
  }
}
