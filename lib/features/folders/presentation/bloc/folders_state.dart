import 'package:shoto/features/folders/domain/entities/folder_entity.dart';

class FoldersState {}

class FoldersInitialState extends FoldersState {}

class FoldersLoadingState extends FoldersState {}

class FoldersLoadedState extends FoldersState {
  final List<FolderEntity> folders;
  FoldersLoadedState(this.folders);
}

class FoldersErrorState extends FoldersState {
  final String message;
  FoldersErrorState(this.message);
}
