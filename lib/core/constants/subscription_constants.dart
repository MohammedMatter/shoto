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

  // The free tier is one number, and this is it: distinct screenshots a free
  // user may bring under organization (favorite and/or file into a folder).
  //
  // There used to be three separate caps — 50 screenshots, 3 folders, 3
  // custom intents — in three different currencies. Nobody can hold that in
  // their head, and two of the three counted things a user has no feel for
  // the value of: being told you have run out of *folders* is a strange
  // sentence, and it arrives while you are trying to tidy up, which is the
  // moment the app was supposed to be helping.
  //
  // One number can be stated on the paywall in one line, understood without
  // reading it twice, and felt: a hundred screenshots is enough that hitting
  // the ceiling means Shoto has genuinely become the place you keep things.
  // Folders and intents are now unlimited, because they are the *organizing*
  // — charging for the containers while giving away the contents had it
  // backwards.
  static const int freeScreenshotLimit = 100;
}
