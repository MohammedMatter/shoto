import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';

/// Sealed for the reason spelled out on `ScreenshotsState`: a state nobody
/// drew is a blank screen, and nothing about `if (state is …)` says what was
/// left out. See `docs/decisions/screen-states.md`.
sealed class FoldersState {}

class FoldersInitialState extends FoldersState {}

class FoldersLoadingState extends FoldersState {}

class FoldersLoadedState extends FoldersState {
  final List<FolderEntity> folders;
  FoldersLoadedState(this.folders);
}

class FoldersErrorState extends FoldersState {
  final AppMessage message;
  FoldersErrorState(this.message);
}
