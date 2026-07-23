import 'package:shoto/features/onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:shoto/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _localDataSource;
  OnboardingRepositoryImpl(this._localDataSource);
  @override
  Future<List<OnboardingItem>> loadOnboardingData() async {
    return _localDataSource.loadOnboardingData();
  }
}
