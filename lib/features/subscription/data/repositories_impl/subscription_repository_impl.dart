import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/features/subscription/data/data_sources/revenue_cat_data_source.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// Applies the developer unlock here rather than at each premium check.
///
/// Every gate in the app — [ensurePremium], the screenshot cap, the folder
/// cap, the settings card — reads its answer from [getStatus], so this is the
/// only place that has to know the switch exists. Repeating the override at
/// each call site is exactly how the inverted premium check happened before.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final RevenueCatDataSource _dataSource;
  final LocalIdentity _localIdentity;
  final DevAccess _devAccess;

  SubscriptionRepositoryImpl(
    this._dataSource,
    this._localIdentity,
    this._devAccess,
  );

  @override
  Future<void> initialize() {
    // The device id. A purchase has to be restorable on this phone after a
    // reinstall, and an anonymous RevenueCat id — what null produces — is
    // regenerated each time, so it cannot do that. Carrying a purchase to a
    // *second* phone is the store account's job: both Play and the App Store
    // restore what the same store account bought, which is the account the
    // user paid with and the only one they should have to remember.
    return _dataSource.initialize(appUserId: _localIdentity.id);
  }

  @override
  Future<SubscriptionStatus> getStatus() async {
    final CustomerInfo? info = await _dataSource.getCustomerInfo();
    return _withDevAccess(_toStatus(info));
  }

  @override
  Stream<SubscriptionStatus> get statusChanges => _dataSource
      .customerInfoUpdates
      .map((info) => _withDevAccess(_toStatus(info)));

  /// The store's answer first, always. Only when it says "not subscribed"
  /// does the tester switch get to speak — so turning the switch off can
  /// never revoke a subscription somebody actually paid for.
  SubscriptionStatus _withDevAccess(SubscriptionStatus status) {
    if (status.isPremium) return status;
    return _devAccess.isUnlocked ? SubscriptionStatus.tester : status;
  }

  @override
  Future<List<SubscriptionPackageInfo>> getOfferings() async {
    final Offering? offering = await _dataSource.getCurrentOffering();
    if (offering == null) return [];

    final List<SubscriptionPackageInfo> packages = [];
    if (offering.monthly != null) {
      packages.add(_toPackageInfo(offering.monthly!, isYearly: false));
    }
    if (offering.annual != null) {
      packages.add(_toPackageInfo(offering.annual!, isYearly: true));
    }
    return packages;
  }

  @override
  Future<SubscriptionStatus> purchase(SubscriptionPackageInfo package) async {
    final CustomerInfo info = await _dataSource.purchase(package.package);
    return _toStatus(info);
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async {
    final CustomerInfo? info = await _dataSource.restorePurchases();
    return _toStatus(info);
  }

  SubscriptionPackageInfo _toPackageInfo(
    Package package, {
    required bool isYearly,
  }) {
    return SubscriptionPackageInfo(
      package: package,
      priceString: package.storeProduct.priceString,
      isYearly: isYearly,
    );
  }

  SubscriptionStatus _toStatus(CustomerInfo? info) {
    if (info == null) return SubscriptionStatus.free;
    final EntitlementInfo? entitlement =
        info.entitlements.active[SubscriptionConstants.entitlementId];
    if (entitlement == null) return SubscriptionStatus.free;
    return SubscriptionStatus(
      isPremium: true,
      expirationDate: DateTime.tryParse(entitlement.expirationDate ?? ''),
    );
  }
}
