import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/domain/use_cases/extract_and_cache_text_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_ocr_text_use_case.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/assign_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/check_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_library_summary_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_by_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_favorite_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_intents_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_intent_done_use_case.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/use_cases/watch_library_changes_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

class ScreenshotsBloc extends Bloc<ScreenshotsEvent, ScreenshotsState> {
  final RequestPhotoPermissionUseCase requestPhotoPermissionUseCase;
  final CheckPhotoPermissionUseCase checkPhotoPermissionUseCase;

  /// Read for one fact only: whether the photo dialog has ever been shown.
  /// See [_blocked].
  final AppPreferences preferences;
  final GetScreenshotsUseCase getScreenshotsUseCase;
  final GetScreenshotsByFolderUseCase getScreenshotsByFolderUseCase;

  /// The local-only counts, read alongside the gallery so the first screen has
  /// something true on it before the slow half finishes. See [_summaryOrNull].
  final GetLibrarySummaryUseCase getLibrarySummaryUseCase;
  final SetFavoriteUseCase setFavoriteUseCase;
  final SetIntentUseCase setIntentUseCase;
  final SetIntentsUseCase setIntentsUseCase;
  final SetIntentDoneUseCase setIntentDoneUseCase;
  final AssignFolderUseCase assignFolderUseCase;
  final DeleteScreenshotsUseCase deleteScreenshotsUseCase;
  final WatchLibraryChangesUseCase watchLibraryChangesUseCase;
  final GetCachedOcrTextUseCase getCachedOcrTextUseCase;
  final ExtractAndCacheTextUseCase extractAndCacheTextUseCase;

  /// Watched, not read: the catalog is what the pickers edit, and a deletion
  /// there changes rows this bloc has already loaded. Nothing else about the
  /// catalog concerns the library — see [IntentCatalog.deletions].
  final IntentCatalog intentCatalog;

  StreamSubscription<void>? _librarySubscription;
  Timer? _refreshDebounce;
  int? _folderId;

  /// Traits already derived, keyed by asset id.
  ///
  /// Survives refreshes, which is what makes the cost a one-off. A screenshot's
  /// recognised text never changes once cached — OCR is run once and stored —
  /// so a result computed for an id stays correct for as long as the bloc
  /// lives, and every resume-triggered reload after the first is free.
  final Map<String, Set<ContentTrait>> _traitCache =
      <String, Set<ContentTrait>>{};

  /// How long a burst of gallery change notifications is allowed to settle
  /// before the library is re-read.
  ///
  /// `PhotoManager` reports device media changes, not app actions, and one
  /// app action is rarely one notification: saving a single screenshot fires
  /// for the file appearing and again as the OS finishes writing it, and an
  /// import of ten fires at least ten times. Every one of those used to run a
  /// full [_loadAndEmit] — enumerate the whole album over the platform
  /// channel, read every `screenshot_meta` row, rebuild every entity — so the
  /// cheapest thing the user can do cost the most expensive read the app has,
  /// several times over, back to back.
  ///
  /// Short enough that a real change still lands well inside the time it takes
  /// to look back at the app, long enough that a burst collapses into one read.
  static const Duration _refreshWindow = Duration(milliseconds: 400);

  /// How many screenshots the trait pass derives before yielding the isolate.
  ///
  /// Deriving traits costs ~700µs each (measured over realistic OCR text), so
  /// a 300-screenshot library is a fifth of a second of solid work. Run in one
  /// go that is a fifth of a second in which the grid cannot scroll and no
  /// frame is produced — on the *first* screen the user sees.
  ///
  /// 25 keeps each burst near 17ms, close to a frame budget, and the `await`
  /// between bursts lets pending frames and taps through. The whole pass still
  /// finishes in well under a second, and only ever once per library.
  static const int traitChunkSize = 25;

  /// How many screenshots one tap of "read them" will recognise.
  ///
  /// Recognition is the expensive thing in this app — hundreds of milliseconds
  /// per image, against microseconds for everything else — so an unbounded
  /// pass over a large library is a progress bar the user watches for minutes
  /// and cannot cancel. A budget turns it into a short, repeatable job: each
  /// run picks up where the last stopped, and the control stays on screen with
  /// a smaller number beside it until there is nothing left to read.
  static const int scanBudget = 40;

  ScreenshotsBloc({
    required this.requestPhotoPermissionUseCase,
    required this.checkPhotoPermissionUseCase,
    required this.getScreenshotsUseCase,
    required this.getScreenshotsByFolderUseCase,
    required this.getLibrarySummaryUseCase,
    required this.setFavoriteUseCase,
    required this.setIntentUseCase,
    required this.setIntentsUseCase,
    required this.setIntentDoneUseCase,
    required this.assignFolderUseCase,
    required this.deleteScreenshotsUseCase,
    required this.watchLibraryChangesUseCase,
    required this.getCachedOcrTextUseCase,
    required this.extractAndCacheTextUseCase,
    required this.intentCatalog,
    required this.preferences,
  }) : super(ScreenshotsInitialState()) {
    intentCatalog.deletions.addListener(_onCustomIntentDeleted);
    on<LoadScreenshotsEvent>(_onLoad);
    on<RecheckPermissionEvent>(_onRecheckPermission);
    on<RequestPhotoAccessEvent>(_onRequestPhotoAccess);
    on<RefreshScreenshotsEvent>(_onRefresh);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<DeleteSelectedEvent>(_onDeleteSelected);
    on<DeleteScreenshotEvent>(_onDeleteScreenshot);
    on<MoveSelectedToFolderEvent>(_onMoveSelected);
    on<MoveScreenshotToFolderEvent>(_onMoveScreenshot);
    on<ToggleSelectItemEvent>(_onToggleSelectItem);
    on<ClearSelectionEvent>(_onClearSelection);
    on<StartGuidedSelectionEvent>(_onStartGuidedSelection);
    on<SelectAllEvent>(_onSelectAll);
    on<SetLibraryFilterEvent>(_onSetLibraryFilter);
    on<SetLibraryLensEvent>(_onSetLibraryLens);
    on<SetLibrarySortEvent>(_onSetLibrarySort);
    on<ComputeTraitsEvent>(_onComputeTraits);
    on<ScanUnreadForTraitsEvent>(_onScanUnread);
    on<SetIntentEvent>(_onSetIntent);
    on<SetIntentForSelectionEvent>(_onSetIntentForSelection);
    on<SetIntentDoneEvent>(_onSetIntentDone);
    on<CustomIntentsChangedEvent>(_onCustomIntentsChanged);
  }

  Future<void> _onLoad(
    LoadScreenshotsEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    _folderId = event.folderId;
    emit(ScreenshotsLoadingState());

    // **Started here, awaited below.** Both reads are now in flight at once:
    // the permission check is a platform channel call that on a cold start also
    // pays for the plugin waking up, and the summary is sqlite. Awaiting them
    // in sequence would spend the whole point of the summary — being ready
    // *early* — waiting on the slower of the two for no reason. Neither depends
    // on the other's answer.
    final Future<LibrarySummary?> summaryRead = _summaryOrNull();

    // **Checks, never asks.** This runs on launch, on every Folders tab
    // select and behind the retry button, and when it asked, the system photo
    // dialog appeared over a user who had just finished the introduction and
    // done nothing else. Android grants that dialog roughly once; spending it
    // at the moment somebody has the least reason to say yes is how an app
    // ends up permanently unable to read anything.
    //
    // Asking now belongs to [RequestPhotoAccessEvent], which a button sends.
    final PermissionState permission = await checkPhotoPermissionUseCase();
    if (!permission.isAuth) {
      emit(_blocked(permission));
      return;
    }

    // **Only when there is something to say.** A summary of an empty library
    // tells Home nothing it did not already assume, and emitting it would put a
    // second loading state on the screen for no visible difference.
    //
    // Emitted *after* the permission check on purpose: numbers drawn from rows
    // the app is no longer allowed to see the pictures for would be a library
    // announced on a screen that is about to say access is blocked.
    final LibrarySummary? summary = await summaryRead;
    if (summary != null && !summary.isEmpty) {
      emit(ScreenshotsLoadingState(summary: summary));
    }

    await _loadAndEmit(emit);
    // Re-read here rather than inside the pickers. The front row is ordered by
    // what this person used most recently, and recomputing that at the moment
    // a sheet opens would reshuffle the chips under a thumb already on its way
    // down. Loading the library is the natural seam: it happens before any
    // picker can be reached, and never while one is open.
    unawaited(intentCatalog.refresh());
    _watchLibrary();
  }

  /// The local counts, or null when they would be wrong or unobtainable.
  ///
  /// Two ways of returning null, and they are different things:
  ///
  /// * **A folder is being loaded.** This summary describes the whole library
  ///   and nothing else; handing it to a screen showing one folder's contents
  ///   would be a number about a different set of pictures.
  /// * **The read threw.** Which is the entire reason this is wrapped: the
  ///   summary is an optimisation on top of a load that is still going to
  ///   happen and still going to succeed or fail on its own terms. A database
  ///   that cannot answer it must cost the user a blank first frame — the
  ///   behaviour that shipped before — and never the library itself.
  Future<LibrarySummary?> _summaryOrNull() async {
    if (_folderId != null) return null;
    try {
      return await getLibrarySummaryUseCase();
    } catch (error) {
      debugPrint('Shoto: library summary unavailable — $error');
      return null;
    }
  }

  /// Which blocked screen a refusal deserves.
  ///
  /// Android reports *denied* both for somebody who said no and for somebody
  /// who was never asked, so the difference is read from preferences — see
  /// [AppPreferences.photoAccessAsked]. The two need opposite screens: one is
  /// offered the dialog, the other is told where system settings are, because
  /// for them the dialog will not come back.
  ScreenshotsState _blocked(PermissionState permission) {
    if (permission == PermissionState.limited) {
      return ScreenshotsPermissionDeniedState(isPartialAccess: true);
    }
    if (!preferences.photoAccessAsked) {
      return ScreenshotsPermissionUnaskedState();
    }
    return ScreenshotsPermissionDeniedState();
  }

  /// Raises the system dialog, once, because somebody pressed a button.
  ///
  /// The flag is set before the result is known and never cleared: what it
  /// records is that the question was *put*, and that stays true whichever way
  /// it was answered. Recording it only on success would send a user who
  /// refused back to the same screen offering the same button, which Android
  /// will silently do nothing about.
  Future<void> _onRequestPhotoAccess(
    RequestPhotoAccessEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    await preferences.markPhotoAccessAsked();
    final PermissionState permission = await requestPhotoPermissionUseCase();
    if (!permission.isAuth) {
      emit(_blocked(permission));
      return;
    }
    emit(ScreenshotsLoadingState());
    await _loadAndEmit(emit);
    unawaited(intentCatalog.refresh());
    _watchLibrary();
  }

  /// Re-evaluates photo access *without* prompting, for use when the app
  /// comes back to the foreground (the user may have just granted access in
  /// system settings).
  ///
  /// Must never call the requesting use case: putting up a permission
  /// dialog is itself an app-lifecycle event, so a lifecycle listener that
  /// prompts would retrigger itself endlessly — dialog, resume, dialog.
  /// That exact loop shipped once and made Home flicker forever.
  Future<void> _onRecheckPermission(
    RecheckPermissionEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    if (state is! ScreenshotsPermissionDeniedState) return;

    final PermissionState permission = await checkPhotoPermissionUseCase();
    if (!permission.isAuth) {
      // Still blocked — leave the existing screen exactly as it is rather
      // than re-emitting, so nothing rebuilds and nothing flickers.
      return;
    }

    emit(ScreenshotsLoadingState());
    await _loadAndEmit(emit);
    _watchLibrary();
  }

  void _watchLibrary() {
    _librarySubscription ??= watchLibraryChangesUseCase().listen(
      (_) => _scheduleRefresh(),
    );
  }

  /// Collapses a burst of change notifications into a single refresh — see
  /// [_refreshWindow]. Restarting the timer on every notification means the
  /// read happens once the device has stopped changing, not once per change.
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(_refreshWindow, () {
      if (!isClosed) add(RefreshScreenshotsEvent());
    });
  }

  Future<void> _onRefresh(
    RefreshScreenshotsEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    // Any pending burst is about to be satisfied by this read, whatever asked
    // for it — the shell also refreshes on every resume, and without this a
    // screenshot saved from the share sheet paid for both.
    _refreshDebounce?.cancel();

    // A refresh must not talk its way past a permission the OS is still
    // refusing. The shell fires one on every resume, and [_loadAndEmit] asks
    // the gallery directly: without access that read comes back *empty*
    // rather than failing, so it emitted an ordinary "loaded, and there is
    // nothing here". Home then said the library was empty and offered the
    // importer, on the same resume the Library tab was asking for photo
    // access — two screens, two different stories, neither of them true.
    //
    // Nothing is re-emitted while access is still missing, so the screen the
    // user is looking at does not flicker; same rule as
    // [_onRecheckPermission], which this now mirrors for the granted case.
    if (state is ScreenshotsPermissionDeniedState) {
      final PermissionState permission = await checkPhotoPermissionUseCase();
      if (!permission.isAuth) return;
      emit(ScreenshotsLoadingState());
      await _loadAndEmit(emit);
      _watchLibrary();
      return;
    }

    await _loadAndEmit(emit);
  }

  Future<void> _loadAndEmit(Emitter<ScreenshotsState> emit) async {
    try {
      final screenshots = _folderId == null
          ? await getScreenshotsUseCase()
          : await getScreenshotsByFolderUseCase(_folderId!);
      final ScreenshotsState previous = state;

      if (previous is! ScreenshotsLoadedState) {
        emit(ScreenshotsLoadedState(screenshots: screenshots));
        // Traits are derived after the grid is on screen, never before it —
        // see [traitChunkSize].
        add(ComputeTraitsEvent());
        return;
      }

      // Nothing on screen would differ, so nothing is emitted.
      //
      // A refresh re-reads the gallery, and every read hands back *new*
      // `AssetEntity` instances even for pictures that never changed. The
      // state has no value equality, so emitting one rebuilt Home, the
      // Library grid and the open viewer — and the thumbnail widgets are
      // keyed off the asset, so a resume with no changes at all still cost a
      // full grid rebuild. See [_sameLibrary].
      if (_sameLibrary(previous.screenshots, screenshots)) return;

      emit(
        ScreenshotsLoadedState(
          screenshots: screenshots,
          selectedIds: previous.selectedIds,
          filter: previous.filter,
          // Carried forward rather than recomputed. The cache is keyed by
          // asset id, so what survives here is still correct for every
          // screenshot that survived the reload; the pass below only has to
          // catch up on ids that are new.
          traits: previous.traits,
          lens: previous.lens,
          traitsReady: previous.traitsReady,
          // Carried like every other choice on this screen. Left off, a
          // refresh — which fires on app resume and on any gallery change —
          // silently put the grid back to newest-first while the header
          // button still claimed the order the user had picked.
          sort: previous.sort,
        ),
      );
      add(ComputeTraitsEvent());
    } catch (error) {
      emit(ScreenshotsErrorState(AppMessage.loadScreenshots));
    }
  }

  /// Whether two reads of the library would put the same thing on screen.
  ///
  /// Compared by id and by the two fields the UI actually draws from metadata,
  /// in order — the gallery read is sorted by capture date, so a stable
  /// library comes back in a stable order and a positional walk is enough.
  /// Anything the app changes itself (favorite, folder, deletion) already
  /// updates the state in place, so this only ever has to catch changes that
  /// came from outside.
  static bool _sameLibrary(
    List<ScreenshotEntity> previous,
    List<ScreenshotEntity> next,
  ) {
    if (previous.length != next.length) return false;
    for (int i = 0; i < previous.length; i++) {
      final ScreenshotEntity before = previous[i];
      final ScreenshotEntity after = next[i];
      if (before.id != after.id ||
          before.isFavorite != after.isFavorite ||
          before.folderId != after.folderId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;

    final target = current.screenshots.firstWhere((s) => s.id == event.assetId);
    final bool newValue = !target.isFavorite;
    final updated = current.screenshots
        .map(
          (s) => s.id == event.assetId ? s.copyWith(isFavorite: newValue) : s,
        )
        .toList();
    emit(current.copyWith(screenshots: updated));
    await setFavoriteUseCase(event.assetId, newValue);
  }

  Future<void> _onDeleteSelected(
    DeleteSelectedEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState || current.selectedIds.isEmpty) {
      return;
    }
    final List<String> ids = current.selectedIds.toList();

    // Only what actually went. Refusing the system prompt used to empty the
    // selection out of the library anyway, leaving the pictures on the phone
    // and their folders, favourites and intents gone.
    final Set<String> deleted = (await deleteScreenshotsUseCase(
      ids,
    )).toSet();
    if (deleted.isEmpty) {
      // Nothing was deleted, so nothing about the library changed — but the
      // selection is cleared regardless. The user answered the question they
      // were asked; leaving them in selection mode reads as the tap having
      // been lost.
      emit(current.copyWith(selectedIds: {}));
      return;
    }

    final updated = current.screenshots
        .where((s) => !deleted.contains(s.id))
        .toList();
    emit(current.copyWith(screenshots: updated, selectedIds: {}));
  }

  Future<void> _onDeleteScreenshot(
    DeleteScreenshotEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    final List<String> deleted = await deleteScreenshotsUseCase([
      event.assetId,
    ]);
    // A refused delete leaves the library exactly as it was — see
    // `_onDeleteSelected`.
    if (deleted.isEmpty) return;

    final updated = current.screenshots
        .where((s) => s.id != event.assetId)
        .toList();
    emit(current.copyWith(screenshots: updated));
  }

  Future<void> _onMoveScreenshot(
    MoveScreenshotToFolderEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    await assignFolderUseCase([event.assetId], event.folderId);
    final updated = current.screenshots
        .map((s) {
          if (s.id != event.assetId) return s;
          return s.copyWith(
            folderId: event.folderId,
            clearFolder: event.folderId == null,
          );
        })
        .where((s) => _folderId == null || s.folderId == _folderId)
        .toList();
    emit(current.copyWith(screenshots: updated));
  }

  Future<void> _onMoveSelected(
    MoveSelectedToFolderEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState || current.selectedIds.isEmpty) {
      return;
    }
    final List<String> ids = current.selectedIds.toList();
    await assignFolderUseCase(ids, event.folderId);
    final updated = current.screenshots
        .map((s) {
          if (!ids.contains(s.id)) return s;
          return s.copyWith(
            folderId: event.folderId,
            clearFolder: event.folderId == null,
          );
        })
        .where((s) => _folderId == null || s.folderId == _folderId)
        .toList();
    emit(current.copyWith(screenshots: updated, selectedIds: {}));
  }

  void _onToggleSelectItem(
    ToggleSelectItemEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;

    // **Safe share picks exactly one, so tapping a second one replaces the
    // first rather than adding to it.**
    //
    // Letting it add was a real confusion and it was reported as one: the
    // toolbar chose its actions purely from the count, so selecting a second
    // screenshot while protecting one made the Protect button disappear and a
    // Merge button take its place. The app silently swapped the job the user
    // had asked for.
    //
    // Handling that by disabling the second tap, or by warning about it,
    // would both be fixes to a state that should not be reachable. Single
    // select makes it unreachable: there is no "2 selected" to be confused by,
    // and tapping around simply moves the choice, which is what a radio
    // control does everywhere else.
    if (current.intent == LibraryIntent.protect) {
      final bool sameOne =
          current.selectedIds.length == 1 &&
          current.selectedIds.first == event.assetId;
      emit(
        current.copyWith(
          // Tapping the chosen one again clears it, so a mis-tap is
          // undoable without leaving the mode.
          selectedIds: sameOne ? <String>{} : <String>{event.assetId},
        ),
      );
      return;
    }

    final Set<String> selected = Set<String>.from(current.selectedIds);
    if (!selected.remove(event.assetId)) selected.add(event.assetId);
    emit(current.copyWith(selectedIds: selected));
  }

  /// Leaving selection mode drops the guiding intent with it.
  ///
  /// Otherwise `isSelectionMode` would still be true — the intent alone keeps
  /// it on — and cancelling would leave the Library in a mode with nothing
  /// selected and no way out.
  void _onClearSelection(
    ClearSelectionEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    emit(current.copyWith(selectedIds: {}, intent: LibraryIntent.none));
  }

  /// Selection mode, opened on somebody else's behalf and with nothing picked.
  ///
  /// The filter is reset to [LibraryFilter.all] at the same time: an intent
  /// arrives from Home, where no filter is visible, and landing in selection
  /// mode over a filtered grid would hide most of the library from a person
  /// who has just been asked to choose from it.
  void _onStartGuidedSelection(
    StartGuidedSelectionEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    emit(
      current.copyWith(
        selectedIds: {},
        intent: event.intent,
        filter: LibraryFilter.all,
      ),
    );
  }

  void _onSelectAll(SelectAllEvent event, Emitter<ScreenshotsState> emit) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    final Set<String> allIds = current.visibleScreenshots
        .map((s) => s.id)
        .toSet();
    emit(current.copyWith(selectedIds: allIds));
  }

  void _onSetLibraryFilter(
    SetLibraryFilterEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    if (current.filter == event.filter) return;
    // Selection is cleared with the filter, because most of what was selected
    // is about to stop being on screen — and a delete button reporting six
    // when four of them are no longer visible is the worst kind of accurate.
    emit(current.copyWith(filter: event.filter, selectedIds: {}));
  }

  /// **Selection survives a sort**, unlike the filter and the lens.
  ///
  /// Re-ordering does not remove anything from the grid — every selected tile
  /// is still there, just somewhere else — so clearing the selection here
  /// would throw away work the user had done for no reason.
  void _onSetLibrarySort(
    SetLibrarySortEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    if (current.sort == event.sort) return;
    emit(current.copyWith(sort: event.sort));
  }

  /// Same contract as the status filter: the visible set changes, so anything
  /// picked is dropped rather than left selected off-screen.
  void _onSetLibraryLens(
    SetLibraryLensEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    if (current.lens == event.lens) return;
    emit(
      current.copyWith(
        lens: event.lens,
        clearLens: event.lens == null,
        selectedIds: {},
      ),
    );
  }

  /// Both intent handlers write the state *before* awaiting the database.
  ///
  /// The tick is the one gesture in this app whose entire purpose is a number
  /// going down, and a round trip to sqflite before the number moves makes it
  /// feel like the tap missed. The write cannot fail in a way the user could
  /// act on anyway — there is no retry for "could not save that you bought a
  /// pair of shoes" — so the optimistic order is honest here.
  Future<void> _onSetIntent(
    SetIntentEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;

    final IntentRef? intent = event.intent;
    emit(
      current.copyWith(
        screenshots: current.screenshots
            .map(
              (ScreenshotEntity s) => s.id != event.assetId
                  ? s
                  // Changing the intent drops any completion with it: having
                  // ticked off "reply" says nothing about whether you have
                  // bought the thing.
                  : s.copyWith(
                      intent: intent == null ? null : IntentState(ref: intent),
                      clearIntent: intent == null,
                    ),
            )
            .toList(),
      ),
    );
    await setIntentUseCase(event.assetId, intent);
  }

  /// Answers the question for everything selected at once.
  ///
  /// The selection is cleared afterwards, like every other bulk action here:
  /// the answer has been given, and leaving forty screenshots lit invites the
  /// next tap to overwrite what was just set.
  Future<void> _onSetIntentForSelection(
    SetIntentForSelectionEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState || current.selectedIds.isEmpty) {
      return;
    }

    final List<String> ids = current.selectedIds.toList();
    final IntentRef? intent = event.intent;
    await setIntentsUseCase(ids, intent);
    emit(
      current.copyWith(
        screenshots: current.screenshots
            .map(
              (ScreenshotEntity s) => !current.selectedIds.contains(s.id)
                  ? s
                  : s.copyWith(
                      intent: intent == null ? null : IntentState(ref: intent),
                      clearIntent: intent == null,
                    ),
            )
            .toList(),
        selectedIds: <String>{},
      ),
    );
  }

  Future<void> _onSetIntentDone(
    SetIntentDoneEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;

    emit(
      current.copyWith(
        screenshots: current.screenshots.map((ScreenshotEntity s) {
          final IntentState? existing = s.intent;
          if (s.id != event.assetId || existing == null) return s;
          return s.copyWith(
            intent: IntentState(
              ref: existing.ref,
              doneAt: event.isDone ? DateTime.now() : null,
            ),
          );
        }).toList(),
      ),
    );
    await setIntentDoneUseCase(event.assetId, event.isDone);
  }

  /// Rebuilds the library after the user edited their own verbs.
  ///
  /// A full reload rather than a patch, because a deletion has already changed
  /// rows this state cannot see: clearing the intent off every screenshot that
  /// carried it happens inside the database, in one transaction, and guessing
  /// at which screenshots those were is how the grid and the table start
  /// disagreeing.
  Future<void> _onCustomIntentsChanged(
    CustomIntentsChangedEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    if (state is! ScreenshotsLoadedState) return;
    await _loadAndEmit(emit);
  }

  /// Reads text out of screenshots nobody has read yet, so the content
  /// filters stop being empty.
  ///
  /// **The filters cannot see anything until this has run.** Every trait is
  /// derived from cached OCR text, and text is only cached when some feature
  /// pays to extract it — so a library that has never been searched has no
  /// traits at all, and used to answer that by hiding the whole row. The row
  /// now asks for this instead.
  ///
  /// Failures are swallowed per screenshot on purpose: one image the
  /// recogniser chokes on must not end a pass over thirty-nine others.
  Future<void> _onScanUnread(
    ScanUnreadForTraitsEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState || current.isScanning) return;

    final Map<String, String> known = await getCachedOcrTextUseCase();
    final List<ScreenshotEntity> unread = <ScreenshotEntity>[
      for (final ScreenshotEntity shot in current.screenshots)
        if (!known.containsKey(shot.id)) shot,
    ];
    if (unread.isEmpty) return;

    emit(current.copyWith(isScanning: true));

    final List<ScreenshotEntity> batch = unread.take(scanBudget).toList();
    for (final ScreenshotEntity shot in batch) {
      if (isClosed) return;
      try {
        final String text = await extractAndCacheTextUseCase(shot);
        _traitCache[shot.id] = ContentTraits.of(text);
      } catch (_) {
        // Recorded as read-and-empty rather than left absent. Absent means
        // "never looked", and a screenshot the recogniser cannot handle would
        // otherwise be retried on every scan forever, holding the control on
        // screen with a count that never reaches zero.
        _traitCache[shot.id] = const <ContentTrait>{};
      }

      current = state;
      if (current is! ScreenshotsLoadedState) return;
      emit(
        current.copyWith(
          traits: Map<String, Set<ContentTrait>>.unmodifiable(_traitCache),
          traitsReady: true,
        ),
      );
    }

    current = state;
    if (current is! ScreenshotsLoadedState) return;
    emit(current.copyWith(isScanning: false));
  }

  /// Derives content traits for anything not already in [_traitCache],
  /// emitting as it goes so counts fill in progressively.
  ///
  /// Reads the OCR cache and nothing else — it never *runs* recognition. That
  /// is what keeps it safe to trigger on every load: for a library nobody has
  /// searched there is simply no text to read, and the pass costs one query
  /// and finishes. Screenshots with no cached text are deliberately left out
  /// of the map entirely so [ScreenshotsLoadedState.unreadCount] can tell
  /// "found nothing" from "never looked".
  Future<void> _onComputeTraits(
    ComputeTraitsEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;

    final Map<String, String> textByAssetId = await getCachedOcrTextUseCase();

    // Ids whose text exists but whose traits are not derived yet. Restricted
    // to the loaded library so a huge cache from another folder's session
    // cannot make this pass longer than the screen it serves.
    final List<String> pending = <String>[
      for (final ScreenshotEntity shot in current.screenshots)
        if (!_traitCache.containsKey(shot.id) &&
            textByAssetId.containsKey(shot.id))
          shot.id,
    ];

    if (pending.isEmpty) {
      // Still publish: the map may have grown on a previous pass, and the
      // first load has to flip `traitsReady` even for a library with no
      // recognised text at all — otherwise the trait row never appears and
      // the user is given no way to learn why.
      if (!current.traitsReady || current.traits.length != _traitCache.length) {
        emit(
          current.copyWith(
            traits: Map<String, Set<ContentTrait>>.unmodifiable(_traitCache),
            traitsReady: true,
          ),
        );
      }
      return;
    }

    for (int start = 0; start < pending.length; start += traitChunkSize) {
      final int end = (start + traitChunkSize).clamp(0, pending.length);
      for (final String assetId in pending.sublist(start, end)) {
        _traitCache[assetId] = ContentTraits.of(textByAssetId[assetId]);
      }

      // Hands the isolate back between bursts so frames and taps get through.
      // Without it this is one long block on the first screen the user sees.
      await Future<void>.delayed(Duration.zero);
      if (isClosed) return;

      current = state;
      if (current is! ScreenshotsLoadedState) return;
      emit(
        current.copyWith(
          traits: Map<String, Set<ContentTrait>>.unmodifiable(_traitCache),
          traitsReady: end == pending.length,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _refreshDebounce?.cancel();
    _librarySubscription?.cancel();
    intentCatalog.deletions.removeListener(_onCustomIntentDeleted);
    return super.close();
  }

  /// A deleted verb has already been cleared off its screenshots in the
  /// database, so the loaded state is now describing rows that no longer say
  /// what it thinks they say.
  void _onCustomIntentDeleted() => add(CustomIntentsChangedEvent());
}
