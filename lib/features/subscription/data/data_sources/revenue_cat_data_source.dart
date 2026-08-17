import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoto/core/constants/subscription_constants.dart';

/// Thin wrapper around the RevenueCat SDK. Every call is defensive —
/// without a real RevenueCat project + App Store Connect/Play Console
/// subscription products behind it (not set up yet, see
/// SubscriptionConstants), the SDK can fail to configure or return empty
/// offerings. None of that should ever crash the app or block the free
/// tier; it should just mean "no premium available right now".
class RevenueCatDataSource {
  StreamController<CustomerInfo>? _customerInfoController;
  bool _configured = false;

  Future<void> initialize({String? appUserId}) async {
    if (_configured) return;
    try {
      final String apiKey = Platform.isIOS
          ? SubscriptionConstants.revenueCatIosApiKey
          : SubscriptionConstants.revenueCatAndroidApiKey;
      if (apiKey.startsWith('REPLACE_WITH')) {
        debugPrint(
          'RevenueCat: skipping configure() — no API key set yet in '
          'SubscriptionConstants.',
        );
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      if (appUserId != null) {
        await Purchases.logIn(appUserId);
      }
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfoController?.add(info);
      });
      _configured = true;
    } catch (error) {
      debugPrint('RevenueCat: initialize failed, staying on free tier: $error');
    }
  }

  /// Attaches this device's entitlements to an account id.
  ///
  /// RevenueCat's own recommended flow, and the reason the app can stay
  /// anonymous until somebody wants an account: `logIn` **aliases** the
  /// anonymous id rather than replacing it, so a purchase made before signing
  /// in follows the user into their account instead of being stranded on a
  /// device id.
  ///
  /// This is what makes a subscription survive a new phone with a *different*
  /// Google account — the entitlement is then keyed to something the store
  /// does not own. See [AccountService].
  Future<void> logIn(String accountId) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(accountId);
    } catch (error) {
      debugPrint('RevenueCat: logIn failed: $error');
    }
  }

  /// Detaches the account, leaving this device anonymous again.
  ///
  /// The entitlement stays with the account on RevenueCat's side; signing back
  /// in brings it back. Signing out of Shoto does not cancel anything, and
  /// nothing local is touched — the library belongs to the device.
  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (error) {
      debugPrint('RevenueCat: logOut failed: $error');
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (error) {
      debugPrint('RevenueCat: getCustomerInfo failed: $error');
      return null;
    }
  }

  Stream<CustomerInfo> get customerInfoUpdates {
    _customerInfoController ??= StreamController<CustomerInfo>.broadcast();
    return _customerInfoController!.stream;
  }

  Future<Offering?> getCurrentOffering() async {
    if (!_configured) return null;
    try {
      final Offerings offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (error) {
      debugPrint('RevenueCat: getOfferings failed: $error');
      return null;
    }
  }

  Future<CustomerInfo> purchase(Package package) async {
    final PurchaseResult result = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return result.customerInfo;
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    return Purchases.restorePurchases();
  }
}
