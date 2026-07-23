import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:shoto/features/onboarding/domain/repositories/onboarding_repository.dart';

class LoadOnboardingDataUseCase {
  OnboardingRepository repository;
  LoadOnboardingDataUseCase(this.repository);
  Future<List<OnboardingItem>> call() async {
    return await repository.loadOnboardingData();
  }
}
