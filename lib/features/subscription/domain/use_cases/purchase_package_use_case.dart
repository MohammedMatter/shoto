import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

class PurchasePackageUseCase {
  final SubscriptionRepository repository;
  PurchasePackageUseCase(this.repository);

  Future<SubscriptionStatus> call(SubscriptionPackageInfo package) =>
      repository.purchase(package);
}
