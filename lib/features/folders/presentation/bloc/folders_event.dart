class FoldersEvent {}

class LoadFoldersEvent extends FoldersEvent {}

class CreateFolderEvent extends FoldersEvent {
  final String name;
  final int color;
  CreateFolderEvent(this.name, this.color);
}

class RenameFolderEvent extends FoldersEvent {
  final int folderId;
  final String name;
  RenameFolderEvent(this.folderId, this.name);
}

class DeleteFolderEvent extends FoldersEvent {
  final int folderId;
  DeleteFolderEvent(this.folderId);
}
