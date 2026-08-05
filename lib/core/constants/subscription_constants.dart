abstract class SubscriptionConstants {
  SubscriptionConstants._();

  // RevenueCat Dashboard > Project settings > API keys.
  // TODO: replace once a RevenueCat account + App Store Connect / Play
  // Console apps exist — see DOCUMENTATION.md "Subscriptions" section.
  static const String revenueCatAndroidApiKey =
      'REPLACE_WITH_REVENUECAT_ANDROID_API_KEY';
  static const String revenueCatIosApiKey =
      'REPLACE_WITH_REVENUECAT_IOS_API_KEY';

  // The entitlement identifier configured in the RevenueCat dashboard that
  // both the monthly and yearly product grant access to.
  static const String entitlementId = 'premium';

  // Fallback display prices shown before real store products are wired up
  // (RevenueCat can't return a real StoreProduct.priceString without an
  // actual App Store Connect / Play Console subscription behind it). The
  // real prices are set when creating those products in each store console
  // — changing these constants alone does NOT change what a user is
  // charged.
  static const String monthlyFallbackPrice = '\$7.00';
  static const String yearlyFallbackPrice = '\$23.00';

  // Screenshots organized into a folder before hitting the free-tier cap.
  static const int freeFolderLimit = 3;

  // Distinct screenshots a free user may "manage" (favorite and/or file
  // into a folder) in total. Screenshots themselves still show up in the
  // gallery beyond this — SHOTO can't hide what the OS already captured —
  // this only gates bringing a new screenshot under organization.
  static const int freeScreenshotLimit = 50;

  // Intents a free user may write in their own words, on top of the fifteen
  // the app ships. Three is enough for anybody to find out whether naming
  // their own is worth anything to them — which is the only honest basis for
  // asking them to pay for the fourth.
  static const int freeCustomIntentLimit = 3;
}
