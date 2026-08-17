import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';

/// Sealed rather than merely abstract — see `docs/decisions/screen-states.md`.
/// `abstract` stopped the base class being instantiated; it did nothing about
/// a subtype being added and never drawn, which is the failure that matters.
sealed class StitchState {}

class StitchInitialState extends StitchState {}

class StitchWorkingState extends StitchState {
  final int step;
  final int total;
  StitchWorkingState(this.step, this.total);

  double? get fraction => total <= 0 ? null : step / total;
}

/// The merge succeeded but nothing has been written yet — the user reviews
/// it first. Merging can only ever be judged by eye, so saving is never
/// automatic.
class StitchReadyState extends StitchState {
  final StitchOutcome outcome;
  final bool isSaving;
  StitchReadyState(this.outcome, {this.isSaving = false});
}

class StitchSavedState extends StitchState {
  final StitchOutcome outcome;
  StitchSavedState(this.outcome);
}

class StitchFailedState extends StitchState {
  final AppMessage message;
  StitchFailedState(this.message);
}
