import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/use_cases/assign_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_by_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_favorite_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/watch_library_changes_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

class ScreenshotsBloc extends Bloc<ScreenshotsEvent, ScreenshotsState> {
  final RequestPhotoPermissionUseCase requestPhotoPermissionUseCase;
  final GetScreenshotsUseCase getScreenshotsUseCase;
  final GetScreenshotsByFolderUseCase getScreenshotsByFolderUseCase;
  final SetFavoriteUseCase setFavoriteUseCase;
  final AssignFolderUseCase assignFolderUseCase;
  final DeleteScreenshotsUseCase deleteScreenshotsUseCase;
  final WatchLibraryChangesUseCase watchLibraryChangesUseCase;

  StreamSubscription<void>? _librarySubscription;
  int? _folderId;

  ScreenshotsBloc({
    required this.requestPhotoPermissionUseCase,
    required this.getScreenshotsUseCase,
    required this.getScreenshotsByFolderUseCase,
    required this.setFavoriteUseCase,
    required this.assignFolderUseCase,
    required this.deleteScreenshotsUseCase,
    required this.watchLibraryChangesUseCase,
  }) : super(ScreenshotsInitialState()) {
    on<LoadScreenshotsEvent>(_onLoad);
    on<RefreshScreenshotsEvent>(_onRefresh);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<DeleteSelectedEvent>(_onDeleteSelected);
    on<DeleteScreenshotEvent>(_onDeleteScreenshot);
    on<MoveSelectedToFolderEvent>(_onMoveSelected);
    on<MoveScreenshotToFolderEvent>(_onMoveScreenshot);
    on<ToggleSelectItemEvent>(_onToggleSelectItem);
    on<ClearSelectionEvent>(_onClearSelection);
    on<ToggleFavoritesFilterEvent>(_onToggleFavoritesFilter);
  }

  Future<void> _onLoad(
    LoadScreenshotsEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    _folderId = event.folderId;
    emit(ScreenshotsLoadingState());
    final PermissionState permission = await requestPhotoPermissionUseCase();
    if (!permission.isAuth && !permission.hasAccess) {
      emit(ScreenshotsPermissionDeniedState());
      return;
    }
    await _loadAndEmit(emit);
    _librarySubscription ??= watchLibraryChangesUseCase().listen(
      (_) => add(RefreshScreenshotsEvent()),
    );
  }

  Future<void> _onRefresh(
    RefreshScreenshotsEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    await _loadAndEmit(emit);
  }

  Future<void> _loadAndEmit(Emitter<ScreenshotsState> emit) async {
    try {
      final screenshots = _folderId == null
          ? await getScreenshotsUseCase()
          : await getScreenshotsByFolderUseCase(_folderId!);
      final ScreenshotsState previous = state;
      final Set<String> selectedIds = previous is ScreenshotsLoadedState
          ? previous.selectedIds
          : <String>{};
      final bool favoritesOnly = previous is ScreenshotsLoadedState
          ? previous.favoritesOnly
          : false;
      emit(
        ScreenshotsLoadedState(
          screenshots: screenshots,
          selectedIds: selectedIds,
          favoritesOnly: favoritesOnly,
        ),
      );
    } catch (error) {
      emit(ScreenshotsErrorState('Could not load your screenshots.'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;

    final target = current.screenshots.firstWhere(
      (s) => s.id == event.assetId,
    );
    final bool newValue = !target.isFavorite;
    final updated = current.screenshots
        .map((s) => s.id == event.assetId ? s.copyWith(isFavorite: newValue) : s)
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
    await deleteScreenshotsUseCase(ids);
    final updated = current.screenshots
        .where((s) => !ids.contains(s.id))
        .toList();
    emit(current.copyWith(screenshots: updated, selectedIds: {}));
  }

  Future<void> _onDeleteScreenshot(
    DeleteScreenshotEvent event,
    Emitter<ScreenshotsState> emit,
  ) async {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    await deleteScreenshotsUseCase([event.assetId]);
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
    final Set<String> selected = Set<String>.from(current.selectedIds);
    if (!selected.remove(event.assetId)) selected.add(event.assetId);
    emit(current.copyWith(selectedIds: selected));
  }

  void _onClearSelection(
    ClearSelectionEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    emit(current.copyWith(selectedIds: {}));
  }

  void _onToggleFavoritesFilter(
    ToggleFavoritesFilterEvent event,
    Emitter<ScreenshotsState> emit,
  ) {
    final ScreenshotsState current = state;
    if (current is! ScreenshotsLoadedState) return;
    emit(current.copyWith(favoritesOnly: !current.favoritesOnly));
  }

  @override
  Future<void> close() {
    _librarySubscription?.cancel();
    return super.close();
  }
}
