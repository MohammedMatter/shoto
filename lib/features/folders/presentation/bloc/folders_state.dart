import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';

/// Sealed for the reason spelled out on `ScreenshotsState`: a state nobody
/// drew is a blank screen, and nothing about `if (state is …)` says what was
/// left out. See `docs/decisions/screen-states.md`.
sealed class FoldersState {}

class FoldersInitialState extends FoldersState {}

class FoldersLoadingState extends FoldersState {}

class FoldersLoadedState extends FoldersState {
  final List<FolderEntity> folders;

  /// Carried on the state rather than held by the page, matching how the
  /// library reports its own order. The shell reloads this bloc on every tab
  /// select, so a sort living in a `StatefulWidget` would be correct until the
  /// user looked at something else and came back.
  final FolderSort sort;

  /// A write that just failed, carried alongside a grid that is still right.
  ///
  /// **Not a [FoldersErrorState].** That state takes over the whole page,
  /// which is the correct answer when the *read* failed and there is genuinely
  /// nothing to show. A failed write is the opposite situation: every folder
  /// the user already had is still there and still correct, and the only new
  /// fact is that one thing they asked for did not happen. Swapping the grid
  /// for an error panel would answer "your new folder could not be made" with
  /// "your folders are gone".
  ///
  /// **One state, then gone.** It is set on the state emitted immediately
  /// after the failure and on no other, so the page can raise a passing
  /// message from a `BlocListener` without it re-appearing on the next reload
  /// — the sort changing, or a trip to Library and back, must not replay a
  /// failure from ten minutes ago.
  final AppMessage? failure;

  FoldersLoadedState(
    this.folders, {
    this.sort = FolderSort.recent,
    this.failure,
  });
}

class FoldersErrorState extends FoldersState {
  final AppMessage message;
  FoldersErrorState(this.message);
}
