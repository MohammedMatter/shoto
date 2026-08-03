class DuplicatesEvent {}

class ScanForDuplicatesEvent extends DuplicatesEvent {}

/// Emitted from inside the scan loop to drive the progress bar.
class ScanProgressEvent extends DuplicatesEvent {
  final int processed;
  final int total;
  ScanProgressEvent(this.processed, this.total);
}

class ToggleCandidateEvent extends DuplicatesEvent {
  final String assetId;
  ToggleCandidateEvent(this.assetId);
}

/// Restores a group's default selection: keep the suggested keeper, mark
/// every other copy for deletion.
class ResetGroupSelectionEvent extends DuplicatesEvent {
  final String groupId;
  ResetGroupSelectionEvent(this.groupId);
}

/// Deselects every copy in a group, so nothing in it gets deleted.
class KeepEntireGroupEvent extends DuplicatesEvent {
  final String groupId;
  KeepEntireGroupEvent(this.groupId);
}

class DeleteSelectedDuplicatesEvent extends DuplicatesEvent {}
