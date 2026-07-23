import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';

class OnboardingState {}

class OnboardingInitialState extends OnboardingState {}

class OnboardingLoadingState extends OnboardingState {}

class OnboardingLoadedState extends OnboardingState {
  final List<OnboardingItem> items;
  OnboardingLoadedState(this.items);
}

class OnboardingErrorState extends OnboardingState {
  final String errorMessage;
  OnboardingErrorState(this.errorMessage);
}
