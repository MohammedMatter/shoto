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
