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
    // The device id, which is a *starting* identity rather than a durable
    // one, and it is worth being exact about what it does and does not
    // survive:
    //
    // * **Same phone, app still installed** — the id is stable, so the
    //   entitlement is found on every launch.
    // * **Reinstall** — `SharedPreferences` goes with the app, so a new id is
    //   minted and RevenueCat sees a stranger. Restoring from the store fixes
    //   it, and Android's own backup often carries the id across anyway.
    // * **New phone, same store account** — the store restores the purchase.
    // * **New phone, different store account** — nothing the store can do:
    //   Google does not move a subscription between Google accounts. That is
    //   the case [AccountService] exists for, and `attachAccount` is how the
    //   entitlement stops depending on the store's identity at all.
    //
    // Passing null instead would produce a *fresh* anonymous id on every
    // launch, which survives nothing.
    return _dataSource.initialize(appUserId: _localIdentity.id);
  }

  @override
  Future<SubscriptionStatus> attachAccount(String accountId) async {
    await _dataSource.logIn(accountId);
    return getStatus();
  }

  @override
  Future<SubscriptionStatus> detachAccount() async {
    await _dataSource.logOut();
    return getStatus();
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
      amount: package.storeProduct.price,
      isYearly: isYearly,
      freeTrialDays: _freeTrialDays(package.storeProduct.introductoryPrice),
    );
  }

  /// An introductory offer is only a *free trial* if it costs nothing.
  ///
  /// Both stores use the same field for "first month at half price", and a
  /// paywall that reads any introductory offer as a trial would promise free
  /// where the store is going to charge — the one lie on that screen nobody
  /// forgives.
  ///
  /// Expressed in days because that is how a trial is said out loud. `cycles`
  /// multiplies the period: Play describes a two-week trial as either
  /// one 14-day cycle or two 7-day ones, and reading only the period turns the
  /// second into "7 days free".
  static int _freeTrialDays(IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return 0;

    final int perCycle = switch (intro.periodUnit) {
      PeriodUnit.day => intro.periodNumberOfUnits,
      PeriodUnit.week => intro.periodNumberOfUnits * 7,
      PeriodUnit.month => intro.periodNumberOfUnits * 30,
      PeriodUnit.year => intro.periodNumberOfUnits * 365,
      PeriodUnit.unknown => 0,
    };

    return perCycle * (intro.cycles < 1 ? 1 : intro.cycles);
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
