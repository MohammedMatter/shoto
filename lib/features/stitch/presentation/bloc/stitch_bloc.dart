import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';
import 'package:shoto/features/stitch/domain/use_cases/save_stitched_image_use_case.dart';
import 'package:shoto/features/stitch/domain/use_cases/stitch_screenshots_use_case.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_event.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_state.dart';

class StitchBloc extends Bloc<StitchEvent, StitchState> {
  final StitchScreenshotsUseCase stitchScreenshotsUseCase;
  final SaveStitchedImageUseCase saveStitchedImageUseCase;

  StitchBloc({
    required this.stitchScreenshotsUseCase,
    required this.saveStitchedImageUseCase,
  }) : super(StitchInitialState()) {
    on<RunStitchEvent>(_onRun);
    on<StitchProgressEvent>(_onProgress);
    on<SaveStitchEvent>(_onSave);
  }

  Future<void> _onRun(RunStitchEvent event, Emitter<StitchState> emit) async {
    emit(StitchWorkingState(0, event.assetIds.length + 2));
    try {
      final StitchOutcome outcome = await stitchScreenshotsUseCase(
        event.assetIds,
        // The merge is one long await, so progress can't be emitted from
        // inside it — it comes back through the event loop instead.
        onProgress: (step, total) => add(StitchProgressEvent(step, total)),
      );
      emit(StitchReadyState(outcome));
    } on StitchException catch (error) {
      // These messages explain what the user can do differently, so they are
      // surfaced verbatim rather than replaced with something generic.
      emit(StitchFailedState(error.message));
    } catch (_) {
      emit(StitchFailedState(AppMessage.stitchFailed));
    }
  }

  void _onProgress(StitchProgressEvent event, Emitter<StitchState> emit) {
    if (state is! StitchWorkingState) return;
    emit(StitchWorkingState(event.step, event.total));
  }

  Future<void> _onSave(SaveStitchEvent event, Emitter<StitchState> emit) async {
    final StitchState current = state;
    if (current is! StitchReadyState || current.isSaving) return;

    emit(StitchReadyState(current.outcome, isSaving: true));
    try {
      await saveStitchedImageUseCase(current.outcome);
      emit(StitchSavedState(current.outcome));
    } catch (_) {
      emit(StitchFailedState(AppMessage.stitchSave));
    }
  }
}
