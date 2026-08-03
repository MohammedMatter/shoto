import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

class GetOfferingsUseCase {
  final SubscriptionRepository repository;
  GetOfferingsUseCase(this.repository);

  Future<List<SubscriptionPackageInfo>> call() => repository.getOfferings();
}
