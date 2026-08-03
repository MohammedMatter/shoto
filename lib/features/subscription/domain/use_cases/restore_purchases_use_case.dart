import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

class RestorePurchasesUseCase {
  final SubscriptionRepository repository;
  RestorePurchasesUseCase(this.repository);

  Future<SubscriptionStatus> call() => repository.restorePurchases();
}
