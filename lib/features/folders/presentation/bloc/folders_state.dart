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

  FoldersLoadedState(this.folders, {this.sort = FolderSort.recent});
}

class FoldersErrorState extends FoldersState {
  final AppMessage message;
  FoldersErrorState(this.message);
}
