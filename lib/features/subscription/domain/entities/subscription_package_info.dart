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

  /// The same price as a number, in the same currency [priceString] is
  /// formatted in.
  ///
  /// Carried alongside the string rather than parsed back out of it: a store
  /// price is formatted for a locale, so "1.234,56 €" and "$1,234.56" are the
  /// same amount and neither is `double.parse`-able. This is what lets the
  /// yearly card state a saving it has actually worked out.
  final double amount;

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
    required this.amount,
    required this.isYearly,
    this.freeTrialDays = 0,
  });

  bool get hasFreeTrial => freeTrialDays > 0;

  /// What a year on this plan costs, whichever plan it is — the common unit
  /// the two cards can be compared in.
  double get yearlyEquivalent => isYearly ? amount : amount * 12;

  /// How much cheaper [this] is than [monthly] over a year, as whole percent,
  /// or null when there is nothing honest to claim.
  ///
  /// Null rather than zero for the cases with no answer: a missing monthly
  /// plan, a free or unpriced product, or a yearly plan that is not actually
  /// cheaper. A badge is a claim, and "Save 0%" is a worse one than silence.
  int? savingAgainst(SubscriptionPackageInfo? monthly) {
    if (!isYearly || monthly == null) return null;
    final double reference = monthly.yearlyEquivalent;
    if (reference <= 0 || amount <= 0 || amount >= reference) return null;
    return ((1 - amount / reference) * 100).round();
  }
}
