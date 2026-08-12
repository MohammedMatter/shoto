import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';

/// **Sealed so that forgetting a state is a compile error, not a blank
/// screen.**
///
/// Home shipped with `isLoading: loaded == null`, which folded four states
/// into one: a refused photo permission and a failed read both drew the
/// loading branch, so the count, the sentence and the import button vanished
/// and the first screen of the app sat empty with no way out of it. Nothing
/// in the code objected, because `is!` costs nothing to write and says
/// nothing about what was left out.
///
/// Sealing changes that. An exhaustive `switch` over this type — one with no
/// `default` — will not compile while a subtype is unhandled, so the next
/// state added here forces every screen that reads it to say what it draws.
/// The guard is only as good as the switches: `if (state is! …)` still
/// compiles and still hides everything, which is why the three ways the
/// library can fail to be a library are drawn once, by [LibraryUnavailable].
sealed class ScreenshotsState {}

class ScreenshotsInitialState extends ScreenshotsState {}

/// The gallery is being read. **Not necessarily with nothing to show.**
///
/// [summary] is the half of the answer that came back from the local tables
/// while the album enumeration was still running — the unsorted count and the
/// waiting verbs, which are facts about the database and not about the gallery.
/// Home draws its real inbox from it, so a cold start opens on the user's own
/// numbers rather than on a blank frame that rearranges itself a second later.
///
/// Null for the reads where it would be wrong or useless: a folder's contents,
/// which this summary does not describe, and any refresh of a library that is
/// already on screen, where the state being replaced is better than a summary
/// of it. Home falls back to neutral placeholders when it is null, and never to
/// nothing.
class ScreenshotsLoadingState extends ScreenshotsState {
  final LibrarySummary? summary;

  ScreenshotsLoadingState({this.summary});
}

/// Photo access has not been asked for yet — not refused, not granted.
///
/// **A separate state because it needs the opposite screen.** Somebody who
/// refused is told where system settings are, because Android will not show
/// the dialog a second time. Somebody who has never been asked must be offered
/// the dialog, and telling *them* to open system settings is telling a person
/// who installed the app a minute ago to go and repair it.
///
/// It exists at all because the app stopped asking at launch. The request used
/// to fire from the first library load, which put a system dialog in front of
/// somebody who had not yet done anything — at the one moment they have the
/// least reason to say yes, spending the single prompt Android grants. Now the
/// app explains itself first and the dialog follows a deliberate tap.
class ScreenshotsPermissionUnaskedState extends ScreenshotsState {}

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

  /// Whether any status filter would show a different set than *All*.
  ///
  /// **A control that cannot change what you see is not a control.** A new
  /// library has nothing filed and nothing favourited, so all three pills
  /// describe the same pictures — and on a fresh install they describe no
  /// pictures at all, three chips reading zero above an empty state that has
  /// already said so. That is the first screen of the app spending its widest
  /// row on the answer "nothing", three times.
  ///
  /// Derived rather than thresholded on purpose. A count like "show them past
  /// four screenshots" is a number somebody has to defend later; this asks the
  /// question the row exists to answer, so the row appears exactly when the
  /// user has made the first distinction it could act on — filed something, or
  /// favourited something — and never before.
  bool get filtersWouldNarrow =>
      favoritesCount > 0 || unsortedCount != screenshots.length;

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

  /// Everything still waiting under [intent], oldest first.
  ///
  /// Oldest first here and newest first everywhere else, on purpose: the
  /// library is a record and you look at the top of it, but a waiting list is
  /// a debt and the thing that has been owed longest belongs at the top.
  List<ScreenshotEntity> waitingFor(IntentRef intent) {
    final List<ScreenshotEntity> waiting = screenshots
        .where((ScreenshotEntity s) => s.intent?.ref == intent && s.isWaiting)
        .toList();
    waiting.sort(
      (ScreenshotEntity a, ScreenshotEntity b) =>
          a.asset.createDateTime.compareTo(b.asset.createDateTime),
    );
    return waiting;
  }

  int doneFor(IntentRef intent) => screenshots
      .where((ScreenshotEntity s) => s.intent?.ref == intent && !s.isWaiting)
      .length;

  /// How many screenshots are waiting under each intent, skipping the ones
  /// with nothing waiting.
  ///
  /// Home reads this to decide what to show at all — an intent nobody has used
  /// must not appear as a permanent zero. Built by walking the library rather
  /// than by asking each known intent in turn, which is both one pass instead
  /// of fifteen and the only version that can see a verb the user invented.
  Map<IntentRef, int> get waitingByIntent {
    final Map<IntentRef, int> counts = <IntentRef, int>{};
    for (final ScreenshotEntity screenshot in screenshots) {
      final IntentState? intent = screenshot.intent;
      if (intent == null || !intent.isWaiting) continue;
      counts.update(intent.ref, (int n) => n + 1, ifAbsent: () => 1);
    }

    // Sorted rather than left in library order, so the section does not
    // reshuffle itself every time a screenshot is added — the same list in the
    // same order is what makes it glanceable.
    final List<MapEntry<IntentRef, int>> ordered = counts.entries.toList()
      ..sort(
        (MapEntry<IntentRef, int> a, MapEntry<IntentRef, int> b) =>
            IntentRef.pickerOrder(a.key).compareTo(IntentRef.pickerOrder(b.key)),
      );
    return Map<IntentRef, int>.fromEntries(ordered);
  }

  /// The app's one shrinking number.
  int get waitingCount =>
      screenshots.where((ScreenshotEntity s) => s.isWaiting).length;

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
