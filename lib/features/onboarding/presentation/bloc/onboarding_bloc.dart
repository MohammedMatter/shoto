import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:shoto/features/onboarding/domain/use_cases/load_onboarding_data_use_case.dart'; // 👈 استدعاء الـ UseCase بدل الـ Repository
import 'package:shoto/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:shoto/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  // حقن الـ UseCase بدلاً من الـ Repository مباشرة لتكون المعمارية نظامية
  final LoadOnboardingDataUseCase loadOnboardingDataUseCase;

  OnboardingBloc(this.loadOnboardingDataUseCase)
    : super(OnboardingInitialState()) {
    on<LoadOnboardingDataEvent>((event, emit) async {
      emit(OnboardingLoadingState());

      try {
        final List<OnboardingItem> items = await loadOnboardingDataUseCase();

        emit(OnboardingLoadedState(items));
      } catch (error) {
        emit(OnboardingErrorState(error.toString()));
      }
    });
  }
}
