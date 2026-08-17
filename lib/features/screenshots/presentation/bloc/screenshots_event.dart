import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';

class ScreenshotsEvent {}

class LoadScreenshotsEvent extends ScreenshotsEvent {
  final int? folderId;
  LoadScreenshotsEvent({this.folderId});
}

/// Fired when the app returns to the foreground while photo access is
/// missing. Checks the permission silently — never prompts.
class RecheckPermissionEvent extends ScreenshotsEvent {}

/// **The only thing in the app that raises the system photo dialog.**
///
/// Deliberately its own event and not a flag on [LoadScreenshotsEvent]: a load
/// happens on launch, on tab select and on retry, and any of those putting up
/// a dialog is how the prompt ended up in front of somebody who had not asked
/// for it. This one is dispatched from a button the user pressed, and from
/// nowhere else.
class RequestPhotoAccessEvent extends ScreenshotsEvent {}

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

/// Turns selection mode on because the user asked for it, with nothing picked.
///
/// Sent by the Select button in the Library and folder headers. That button is
/// how the mode is entered now that a long-press on a thumbnail opens that
/// screenshot's own actions instead — a gesture with no affordance was the
/// only door to bulk actions, and the button is the affordance.
class EnterSelectionModeEvent extends ScreenshotsEvent {}

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

/// Flips the grid between newest-first and oldest-first.
///
/// Its own event for the same reason the lens has one: order is independent of
/// which slice and which contents are showing, so folding it into either would
/// make the caller re-state a choice it has no opinion about.
class SetLibrarySortEvent extends ScreenshotsEvent {
  final LibrarySort sort;
  SetLibrarySortEvent(this.sort);
}

/// Narrows the grid to screenshots whose contents carry [lens], or clears the
/// narrowing when null.
///
/// Separate from [SetLibraryFilterEvent] because the two axes are independent:
/// status and content can both be on, so one event carrying both would have to
/// re-state the other axis on every tap.
class SetLibraryLensEvent extends ScreenshotsEvent {
  final ContentTrait? lens;
  SetLibraryLensEvent(this.lens);
}

/// Runs text recognition over screenshots nobody has read yet, so the content
/// filters have something to work from.
///
/// Budgeted rather than exhaustive — see [ScreenshotsBloc.scanBudget].
class ScanUnreadForTraitsEvent extends ScreenshotsEvent {}

/// Records what the user says they will do with a screenshot, or clears it
/// with a null [intent].
class SetIntentEvent extends ScreenshotsEvent {
  final String assetId;
  final IntentRef? intent;
  SetIntentEvent(this.assetId, this.intent);
}

/// The same answer for everything currently selected, or clears it with a null
/// [intent].
///
/// The only way a library that predates the question ever gets answered: doing
/// it one screenshot at a time is a thousand sheets, so nobody does it and the
/// waiting list stays a feature that only applies to screenshots taken from
/// now on.
class SetIntentForSelectionEvent extends ScreenshotsEvent {
  final IntentRef? intent;
  SetIntentForSelectionEvent(this.intent);
}

/// Re-reads the library after a custom intent was renamed or deleted.
///
/// Deleting one clears it off every screenshot that carried it, in the
/// database, underneath the loaded state — so the state has to be rebuilt
/// rather than patched, or the grid keeps showing a verb that no longer
/// exists.
class CustomIntentsChangedEvent extends ScreenshotsEvent {}

/// Ticks an intent off, or puts it back on the waiting list.
class SetIntentDoneEvent extends ScreenshotsEvent {
  final String assetId;
  final bool isDone;
  SetIntentDoneEvent(this.assetId, this.isDone);
}

/// Derives content traits for the loaded library from already-cached OCR text.
///
/// Its own event rather than part of the load, because it is far too slow to
/// sit in front of the grid — see [ScreenshotsBloc.traitChunkSize].
class ComputeTraitsEvent extends ScreenshotsEvent {}
