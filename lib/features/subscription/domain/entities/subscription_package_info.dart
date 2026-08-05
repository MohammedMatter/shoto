import 'package:purchases_flutter/purchases_flutter.dart';

/// Wraps a RevenueCat [Package] with the display strings the paywall needs.
/// Keeping the raw package (rather than re-modeling it) is a deliberate
/// pragmatic choice — same reasoning as [ScreenshotEntity] keeping a raw
/// `photo_manager` `AssetEntity`: it's a handle to an external SDK's object,
/// not UI, and re-wrapping it fully would add indirection without benefit.
///
/// **There is no `title` here, and that is the fix rather than an omission.**
/// There used to be one, filled in by the repository as
/// `isYearly ? 'Yearly' : 'Monthly'` — two English literals manufactured in
/// the data layer, where no locale is knowable. They were never rendered: the
/// paywall passes `context.l10n.paywallYearly` / `paywallMonthly` straight to
/// the card, so the field was dead weight that only *looked* like a
/// localization bug. Deleting it means the next person cannot reach for it and
/// accidentally ship the English.
class SubscriptionPackageInfo {
  final Package package;

  /// The price as the store formatted it — already in the user's currency and
  /// locale, and therefore the one string here that must **not** be
  /// translated by us.
  final String priceString;

  final bool isYearly;

  /// How many days this product is free for before the first charge, or zero.
  ///
  /// **Read from the store, never from a constant.** Whether a trial exists at
  /// all is configured in Play Console and App Store Connect; an app that
  /// hardcodes "7 days free" prints that sentence whether or not the store
  /// agrees, and the first person to find out is the one who gets charged on
  /// day one. Zero here means the paywall says nothing about a trial, which is
  /// the correct behaviour for a product that does not have one — including
  /// today, before any store product exists.
  final int freeTrialDays;

  const SubscriptionPackageInfo({
    required this.package,
    required this.priceString,
    required this.isYearly,
    this.freeTrialDays = 0,
  });

  bool get hasFreeTrial => freeTrialDays > 0;
}
