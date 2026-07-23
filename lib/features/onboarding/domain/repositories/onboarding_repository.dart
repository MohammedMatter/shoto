
import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';

abstract class OnboardingRepository {
  Future<List<OnboardingItem>> loadOnboardingData();
}
