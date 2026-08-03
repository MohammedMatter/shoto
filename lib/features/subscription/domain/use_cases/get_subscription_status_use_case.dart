import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

class GetSubscriptionStatusUseCase {
  final SubscriptionRepository repository;
  GetSubscriptionStatusUseCase(this.repository);

  Future<SubscriptionStatus> call() => repository.getStatus();
}
