import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:shoto/features/smart_actions/domain/use_cases/get_screenshot_actions_use_case.dart';

abstract class SmartActionsState {}

class SmartActionsLoadingState extends SmartActionsState {}

class SmartActionsLoadedState extends SmartActionsState {
  final List<DetectedAction> actions;
  SmartActionsLoadedState(this.actions);

  bool get isEmpty => actions.isEmpty;
}

class SmartActionsErrorState extends SmartActionsState {}

/// Drives the actions sheet for one screenshot.
///
/// A cubit rather than a bloc: there is exactly one thing that ever happens
/// here — scan this image, once — so the event plumbing every other feature
/// in the app needs would be ceremony with nothing behind it.
class SmartActionsCubit extends Cubit<SmartActionsState> {
  final GetScreenshotActionsUseCase getScreenshotActionsUseCase;

  SmartActionsCubit(this.getScreenshotActionsUseCase)
    : super(SmartActionsLoadingState());

  Future<void> scan(ScreenshotEntity screenshot) async {
    emit(SmartActionsLoadingState());
    try {
      emit(
        SmartActionsLoadedState(await getScreenshotActionsUseCase(screenshot)),
      );
    } catch (_) {
      emit(SmartActionsErrorState());
    }
  }
}
