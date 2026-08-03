import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';

class ScreenshotsEvent {}

class LoadScreenshotsEvent extends ScreenshotsEvent {
  final int? folderId;
  LoadScreenshotsEvent({this.folderId});
}

/// Fired when the app returns to the foreground while photo access is
/// missing. Checks the permission silently — never prompts.
class RecheckPermissionEvent extends ScreenshotsEvent {}

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

/// Turns selection mode on **before anything is selected**, on behalf of a
/// screen that cannot do the picking itself.
///
/// See [LibraryIntent]. Sent by Home when somebody taps a tool that needs
/// screenshots — the Library then opens already waiting, rather than the user
/// being told which gesture to perform.
class StartGuidedSelectionEvent extends ScreenshotsEvent {
  final LibraryIntent intent;
  StartGuidedSelectionEvent(this.intent);
}

class SelectAllEvent extends ScreenshotsEvent {}

/// Names the slice to show, rather than flipping a switch.
///
/// The toggle it replaces could only ever mean "the other one", which stops
/// working the moment there are three — and it made the caller that matters
/// most impossible to write: Home has to be able to say *which* slice it
/// wants, not ask for whatever isn't showing.
class SetLibraryFilterEvent extends ScreenshotsEvent {
  final LibraryFilter filter;
  SetLibraryFilterEvent(this.filter);
}
