import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';

abstract class SubscriptionRepository {
  /// Configures the RevenueCat SDK. Safe to call even without real API
  /// keys/store products configured yet — failures are swallowed so the
  /// app still runs fully on the free tier.
  Future<void> initialize();

  Future<SubscriptionStatus> getStatus();
  Stream<SubscriptionStatus> get statusChanges;
  Future<List<SubscriptionPackageInfo>> getOfferings();
  Future<SubscriptionStatus> purchase(SubscriptionPackageInfo package);
  Future<SubscriptionStatus> restorePurchases();
}
