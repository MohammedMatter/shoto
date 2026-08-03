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

  const SubscriptionPackageInfo({
    required this.package,
    required this.priceString,
    required this.isYearly,
  });
}
