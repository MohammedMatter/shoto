abstract class StitchEvent {}

/// Starts merging the given selection.
class RunStitchEvent extends StitchEvent {
  final List<String> assetIds;
  RunStitchEvent(this.assetIds);
}

/// Progress relayed back from the merge, which runs inside a single async
/// call and so can't emit states directly.
class StitchProgressEvent extends StitchEvent {
  final int step;
  final int total;
  StitchProgressEvent(this.step, this.total);
}

/// Writes the finished image to the gallery.
class SaveStitchEvent extends StitchEvent {}
