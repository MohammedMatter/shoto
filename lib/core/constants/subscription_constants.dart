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
  static const String monthlyFallbackPrice = '\$4.99';
  static const String yearlyFallbackPrice = '\$24.99';

  /// The same two prices as numbers, so the saving on the yearly card can be
  /// *calculated* rather than asserted.
  ///
  /// The badge used to read a hardcoded "Save 73%". That was true of these two
  /// preview figures and of nothing else: the moment a real store product
  /// exists, the prices come from App Store Connect and Play Console in the
  /// user's own currency, and a number typed into the source has no way of
  /// knowing what they say. A percentage that is wrong on a paywall is not a
  /// cosmetic error — it is a claim about money.
  /// **Down from 7 and 23**, and the ratio is the point as much as the
  /// numbers.
  ///
  /// Seven a month is a professional-tool price, and this competes with things
  /// the phone does for nothing — a ceiling that high asks somebody to value a
  /// screenshot organiser above their music subscription. Seven also made the
  /// pair read as a trick: twelve months at seven is 84 against a 23 year, a
  /// 73% discount, which is not a saving so much as an admission that the
  /// monthly price was never meant to be paid. A monthly plan nobody is
  /// supposed to take is a monthly plan nobody trusts.
  ///
  /// Five and twenty-five is the ordinary shape for this category: the year
  /// costs five months, the discount reads as generous rather than as bait,
  /// and the monthly is low enough to be a real choice for somebody who wants
  /// to try Pro for a month before committing.
  static const double monthlyFallbackAmount = 4.99;
  static const double yearlyFallbackAmount = 24.99;

  // The free tier is two numbers: this one, and [freeFolderLimit] below.
  //
  // It was three caps — 50 screenshots, 3 folders, 3 custom intents — then
  // one, and it is two now. The argument for one is written out under the
  // folder limit along with the reason it was overruled; custom intents stay
  // uncapped.
  //
  // **Fifty.** It was a hundred, then fifteen, and both were wrong in the same
  // way — they were guesses about when somebody would feel the value, made
  // from opposite ends.
  //
  // A hundred meant most people never met the paywall at all: the free tier
  // was the whole product and the price was a rumour. Fifteen was reached in
  // the first week, which sounds ideal and is the trap: **the cap is on
  // organising**, and organising is the habit this app is trying to build.
  // Somebody stopped at fifteen has not yet learned that Shoto is where their
  // screenshots live; they have learned that it stops working. A tool that
  // interrupts the loop it is teaching does not get a second chance, and it
  // spends the interruption on the one action that costs nothing to allow.
  //
  // Fifty is a month or two of ordinary filing. Long enough for the library to
  // become the place you look first — which is the only state in which paying
  // is obvious — and short enough that anybody using the app properly still
  // arrives. The paid features are what should sell Pro; the ceiling is what
  // catches the people the features already convinced.
  //
  // Changing this number changes what existing free users see immediately,
  // and deliberately in the safe direction: the gate refuses only *new*
  // items, so somebody already holding forty keeps all forty and is simply
  // over the line. See `LibraryQuota.fraction`, which clamps for exactly this.
  static const int freeScreenshotLimit = 50;

  /// How many folders a free user may have at once.
  ///
  /// **This cap was removed once, deliberately, and is back by decision.** The
  /// note that removed it is worth keeping rather than deleting, because it is
  /// the case anybody re-reading this line will want to weigh: a folder is not
  /// a feature somebody enjoys, it is the work of tidying up — the very habit
  /// the app is trying to build — and charging for the containers while giving
  /// away the contents had it backwards. "You have run out of folders" is also
  /// a strange sentence to meet mid-tidy.
  ///
  /// What overrules it is that folders are the thing free users actually reach
  /// for first, and a free tier whose only ceiling is fifty screenshots is one
  /// most people never meet at all.
  ///
  /// **Three, and the starter set is two.** The gap is deliberate: a set the
  /// exact size of the allowance would mean the first folder somebody names
  /// *themselves* is the one that meets the paywall — their own idea, priced
  /// at the moment they have it. Two suggested and one to invent puts the
  /// price on the fourth instead, which is after they have filed something of
  /// their own into something of their own. See `defaultFolderSeeds`.
  ///
  /// Like the screenshot cap, this refuses only *new* folders. Anybody already
  /// holding more than three — every install that has been running since
  /// before this line existed, which is all of them — keeps every one of them.
  /// See `ensureUnderFolderLimit`.
  static const int freeFolderLimit = 3;
}
