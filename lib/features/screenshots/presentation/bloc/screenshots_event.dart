class ScreenshotsEvent {}

class LoadScreenshotsEvent extends ScreenshotsEvent {
  final int? folderId;
  LoadScreenshotsEvent({this.folderId});
}

class RefreshScreenshotsEvent extends ScreenshotsEvent {}

class ToggleFavoriteEvent extends ScreenshotsEvent {
  final String assetId;
  ToggleFavoriteEvent(this.assetId);
}

class DeleteSelectedEvent extends ScreenshotsEvent {}

class DeleteScreenshotEvent extends ScreenshotsEvent {
  final String assetId;
  DeleteScreenshotEvent(this.assetId);
}

class MoveSelectedToFolderEvent extends ScreenshotsEvent {
  final int? folderId;
  MoveSelectedToFolderEvent(this.folderId);
}

class MoveScreenshotToFolderEvent extends ScreenshotsEvent {
  final String assetId;
  final int? folderId;
  MoveScreenshotToFolderEvent(this.assetId, this.folderId);
}

class ToggleSelectItemEvent extends ScreenshotsEvent {
  final String assetId;
  ToggleSelectItemEvent(this.assetId);
}

class ClearSelectionEvent extends ScreenshotsEvent {}

class ToggleFavoritesFilterEvent extends ScreenshotsEvent {}
