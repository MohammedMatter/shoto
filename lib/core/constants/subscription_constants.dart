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

  /// The same two prices as numbers, so the saving on the yearly card can be
  /// *calculated* rather than asserted.
  ///
  /// The badge used to read a hardcoded "Save 73%". That was true of these two
  /// preview figures and of nothing else: the moment a real store product
  /// exists, the prices come from App Store Connect and Play Console in the
  /// user's own currency, and a number typed into the source has no way of
  /// knowing what they say. A percentage that is wrong on a paywall is not a
  /// cosmetic error — it is a claim about money.
  static const double monthlyFallbackAmount = 7;
  static const double yearlyFallbackAmount = 23;

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
  // reading it twice, and felt. Folders and intents are unlimited, because
  // they are the *organizing* — charging for the containers while giving away
  // the contents had it backwards.
  //
  // **Fifteen, down from a hundred.** A hundred was set so that hitting the
  // ceiling would mean Shoto had genuinely become the place you keep things —
  // which is a fine sentiment and a poor business: on a normal week of filing
  // it is a limit most people never reach, so the free tier was the whole
  // product and the paywall was a rumour. Fifteen is reached in the first
  // week or two by anybody the app is actually working for, and reached by
  // *organizing* — which is the moment the value is most obvious and the
  // upgrade makes the most sense.
  //
  // Changing this number changes what existing free users see immediately,
  // and deliberately in the safe direction: the gate refuses only *new*
  // items, so somebody already holding forty keeps all forty and is simply
  // over the line. See `LibraryQuota.fraction`, which clamps for exactly this.
  static const int freeScreenshotLimit = 15;
}
