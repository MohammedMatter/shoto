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

  /// Moves this device's entitlements onto an account, and reports what the
  /// account is entitled to afterwards.
  ///
  /// Called when somebody signs in. A purchase made anonymously before that
  /// follows them in rather than being stranded on a device id.
  Future<SubscriptionStatus> attachAccount(String accountId);

  /// Detaches the account. The entitlement stays with it on RevenueCat's side;
  /// signing back in anywhere brings it back.
  Future<SubscriptionStatus> detachAccount();
}
