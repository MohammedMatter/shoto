import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/utils/text_folding.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/delete_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/seed_default_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/update_folder_use_case.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';

class FoldersBloc extends Bloc<FoldersEvent, FoldersState> {
  final GetFoldersUseCase getFoldersUseCase;
  final CreateFolderUseCase createFolderUseCase;
  final UpdateFolderUseCase updateFolderUseCase;
  final DeleteFolderUseCase deleteFolderUseCase;
  final SeedDefaultFoldersUseCase seedDefaultFoldersUseCase;

  /// The chosen order, kept on the bloc because the shell fires
  /// `LoadFoldersEvent` on every visit to the tab — a sort held anywhere else
  /// would be reset by walking away and coming back.
  FolderSort _sort = FolderSort.recent;

  FoldersBloc({
    required this.getFoldersUseCase,
    required this.createFolderUseCase,
    required this.updateFolderUseCase,
    required this.deleteFolderUseCase,
    required this.seedDefaultFoldersUseCase,
  }) : super(FoldersInitialState()) {
    on<LoadFoldersEvent>(_onLoad);
    on<CreateFolderEvent>(_onCreate);
    on<UpdateFolderEvent>(_onUpdate);
    on<DeleteFolderEvent>(_onDelete);
    on<SetFolderSortEvent>(_onSetSort);
    on<SeedDefaultFoldersEvent>(_onSeedDefaults);
  }

  /// **Only announces loading when there is nothing on screen to keep.**
  ///
  /// This is a reload, and almost every reload in this feature happens *behind*
  /// a grid that is already right: the shell fires `LoadFoldersEvent` on every
  /// visit to the tab, and creating, renaming or deleting a folder all end here
  /// too. Emitting [FoldersLoadingState] unconditionally meant every one of
  /// those blanked the page — the folders page draws nothing at all for that
  /// state, deliberately — so making a folder read as *the whole grid
  /// disappearing and coming back with one more tile in it*, which is a far
  /// louder event than the one that actually happened.
  ///
  /// The read behind it is a local SQLite query measured in milliseconds, so
  /// the grid the user is already looking at is never meaningfully stale while
  /// it stands. The loading state survives for the one case it was written for:
  /// the very first load, where there is genuinely nothing to show yet.
  Future<void> _onLoad(
    LoadFoldersEvent event,
    Emitter<FoldersState> emit, {

    /// Set only by the write handlers below, which reload through here after
    /// something failed. See [FoldersLoadedState.failure].
    AppMessage? failure,
  }) async {
    if (state is! FoldersLoadedState) emit(FoldersLoadingState());
    try {
      final folders = await getFoldersUseCase();
      emit(FoldersLoadedState(_sorted(folders), sort: _sort, failure: failure));
    } catch (error) {
      emit(FoldersErrorState(AppMessage.loadFolders));
    }
  }

  /// **Every write is caught, and none of them used to be.**
  ///
  /// The read above has always surfaced its failures; the three writes below
  /// had no `catch` at all, so a write that threw escaped to the bloc's error
  /// channel and the page was left exactly as it was. What the user saw was
  /// the folder they had just named, coloured and given a glyph simply not
  /// appearing — with no message, and nothing to retry.
  ///
  /// The answer is not the error *state*: that blanks the grid, and the grid
  /// is still correct. Instead the reload happens either way — so the screen
  /// tells the truth about what actually exists — and the message rides along
  /// on the loaded state for the page to say out loud once.
  Future<void> _write(
    Emitter<FoldersState> emit,
    AppMessage onFailure,
    Future<void> Function() write,
  ) async {
    AppMessage? failure;
    try {
      await write();
    } catch (error) {
      failure = onFailure;
    }
    await _onLoad(LoadFoldersEvent(), emit, failure: failure);
  }

  Future<void> _onCreate(CreateFolderEvent event, Emitter<FoldersState> emit) =>
      _write(
        emit,
        AppMessage.saveFolder,
        () => createFolderUseCase(
          event.name,
          event.color,
          isPrivate: event.isPrivate,
          iconKey: event.iconKey,
        ),
      );

  Future<void> _onUpdate(UpdateFolderEvent event, Emitter<FoldersState> emit) =>
      _write(
        emit,
        AppMessage.saveFolder,
        () => updateFolderUseCase(
          event.folderId,
          name: event.name,
          color: event.color,
          iconKey: event.iconKey,
        ),
      );

  Future<void> _onDelete(DeleteFolderEvent event, Emitter<FoldersState> emit) =>
      _write(
        emit,
        AppMessage.deleteFolder,
        () => deleteFolderUseCase(event.folderId),
      );

  /// Re-orders what is already loaded rather than going back to the database.
  ///
  /// Deliberately **not** a reload: every sort this screen offers is over data
  /// the state is already holding, and a reload would blank the grid through
  /// `FoldersLoadingState` on the way — the user would watch the folders
  /// disappear and come back in a different order, for a change that costs a
  /// list sort.
  void _onSetSort(SetFolderSortEvent event, Emitter<FoldersState> emit) {
    _sort = event.sort;
    final FoldersState current = state;
    if (current is! FoldersLoadedState) return;
    emit(FoldersLoadedState(_sorted(current.folders), sort: _sort));
  }

  Future<void> _onSeedDefaults(
    SeedDefaultFoldersEvent event,
    Emitter<FoldersState> emit,
  ) async {
    try {
      final bool seeded = await seedDefaultFoldersUseCase(event.seeds);
      // Nothing written means the offer had already been made, and the grid on
      // screen is already right.
      if (!seeded) return;
      await _onLoad(LoadFoldersEvent(), emit);
    } catch (error) {
      // Swallowed on purpose, and it is the only `catch` in this bloc that
      // does not surface. Seeding is something Shoto offered rather than
      // something the user asked for; failing it means the Folders tab is
      // empty, which is exactly the screen that shipped before this existed.
      // An error banner would report a task nobody started.
    }
  }

  /// Sorting happens here rather than in SQL.
  ///
  /// Two of the three orders cannot be expressed in the folders query at all:
  /// the screenshot count is assembled in Dart from a second `GROUP BY`, and
  /// name order has to fold case *and* accents in a way SQLite's
  /// `COLLATE NOCASE` only manages for ASCII — which would put "École" after
  /// "Zoo" on a French phone.
  ///
  /// **That claim used to be false here too.** This sorted on
  /// `toLowerCase().compareTo(…)`, which orders by UTF-16 code unit and puts
  /// É (U+00C9) past every unaccented letter — so the one thing being done in
  /// Dart to avoid a bad collation reproduced it exactly. See
  /// [foldForMatching], which is now what both this and the grid's search run
  /// on.
  List<FolderEntity> _sorted(List<FolderEntity> folders) {
    final List<FolderEntity> sorted = List<FolderEntity>.of(folders);
    switch (_sort) {
      case FolderSort.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case FolderSort.name:
        // Folded once per folder rather than once per comparison: `sort` calls
        // the comparator O(n log n) times, and every call would otherwise
        // build two new strings.
        final Map<int, String> keys = <int, String>{
          for (final FolderEntity folder in folders)
            folder.id: foldForMatching(folder.name),
        };
        sorted.sort((a, b) {
          final int byName = keys[a.id]!.compareTo(keys[b.id]!);
          // "Café" and "Cafe" fold to one string, and `List.sort` is not
          // stable — without a tie-break the two swap places between rebuilds.
          return byName != 0 ? byName : b.createdAt.compareTo(a.createdAt);
        });
      case FolderSort.fullest:
        sorted.sort((a, b) {
          final int byCount = b.screenshotCount.compareTo(a.screenshotCount);
          // Ties fall back to newest first, so a screen of empty folders is
          // still in a stable, meaningful order rather than in whatever order
          // the sort happened to leave them.
          return byCount != 0 ? byCount : b.createdAt.compareTo(a.createdAt);
        });
    }
    return sorted;
  }
}
