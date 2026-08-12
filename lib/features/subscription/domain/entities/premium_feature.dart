import 'package:flutter/material.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/localization/l10n.dart';

/// The single source of truth for what paying actually gets you.
///
/// Every paid capability grew its own gate over time, and the paywall was
/// still advertising three generic bullet points written before most of them
/// existed — someone hitting it had no way to know the app could read text
/// out of their screenshots, merge a scrolling capture, or find duplicates.
/// A person deciding whether to subscribe deserves the real list, and the
/// only way to keep that list honest is for one place to own it.
///
/// Adding a premium feature means adding it here; the paywall, the settings
/// card and the upgrade prompts all read from this.
class PremiumFeature {
  final IconData icon;

  /// Resolved from a [BuildContext] rather than stored as a plain string,
  /// because every one of these is translated. A `const` list of literals
  /// would have frozen the paywall in English no matter what language the
  /// rest of the app was speaking.
  final String Function(BuildContext) title;

  /// Concrete, in the user's terms. "Search inside your screenshots" beats
  /// "advanced search" — the second says nothing.
  final String Function(BuildContext) description;

  /// What to say instead once the reader **already pays**, when the ordinary
  /// line would be describing a restriction that no longer applies to them.
  ///
  /// Null for almost everything, and that is the point: most of these describe
  /// a capability, and a capability reads the same whether you have it yet or
  /// not. Only the library ceiling is phrased as a *limit* — "the free tier
  /// organizes 100 screenshots" — which is a sentence about somebody else's
  /// account once you have paid to leave it behind. A subscriber opening this
  /// page to check what they get should not have to work out that the
  /// hundred-screenshot line is the thing they are no longer subject to.
  ///
  /// Kept here rather than resolved in the page, because this class is
  /// documented as the single source of truth for what paying gets you, and a
  /// page picking different words for the same feature is exactly the drift
  /// that doc exists to prevent.
  final String Function(BuildContext)? descriptionWhenPro;

  /// The paragraph behind the one-liner: what the feature actually does when
  /// you use it, in plain words.
  ///
  /// [description] has to fit on a paywall row, so it can only ever be a
  /// claim. This is where the claim gets explained — and it only ever
  /// appears on the "What is included" screen, which somebody opened
  /// *because* they wanted the longer answer.
  final String Function(BuildContext) how;

  /// Three checkable specifics, each one something the app genuinely does.
  ///
  /// Deliberately concrete rather than adjectival: "card numbers are
  /// Luhn-checked" is verifiable and "powerful detection" is not. Anything
  /// written here that the code does not do is a lie the user finds out
  /// about the first time they try it.
  final List<String Function(BuildContext)> points;

  const PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.how,
    required this.points,
    this.descriptionWhenPro,
  });

  /// The description to show, given whether the reader is a subscriber.
  ///
  /// One place makes this choice so no caller has to remember the fallback.
  String describe(BuildContext context, {required bool isPro}) =>
      (isPro ? descriptionWhenPro : null)?.call(context) ??
      description(context);

  /// **Never list something the app cannot do.**
  ///
  /// This list headed with "Rules that file for you" for a while after the
  /// filing-rules feature was deleted, so the first thing anyone read on the
  /// paywall — the screen where they decide to pay — was a promise nothing in
  /// the app could keep. Removing a feature means removing its entry here in
  /// the same change; the class doc above says this list is the source of
  /// truth, and a source of truth that lags reality is worse than no list.
  /// Safe Share is first, and search is gone.
  ///
  /// **Search left** because it is free now. Listing it here would have been
  /// the exact failure the paragraph above describes, pointed the other way:
  /// charging for something the app hands out, on the screen where somebody
  /// decides whether to trust the price.
  ///
  /// **Safe Share leads** because it is the only thing in this list that
  /// neither Google Photos nor Apple Photos will ever ship. They both OCR
  /// every screenshot for free, index it and search it, so "find your
  /// screenshots" is a commodity the OS gives away — but neither platform can
  /// approve a feature that helpfully writes a *different, plausible* card
  /// number into a user's photo. Whatever is genuinely ours belongs at the
  /// top, because the first row is the one people read.
  static final List<PremiumFeature> all = [
    PremiumFeature(
      icon: Icons.shield_outlined,
      title: (context) => context.l10n.featSafeShare,
      description: (context) => context.l10n.featSafeShareBody,
      how: (context) => context.l10n.featSafeShareHow,
      points: [
        (context) => context.l10n.featSafeSharePoint1,
        (context) => context.l10n.featSafeSharePoint2,
        (context) => context.l10n.featSafeSharePoint3,
      ],
    ),
    PremiumFeature(
      icon: Icons.auto_fix_high_rounded,
      title: (context) => context.l10n.featActions,
      description: (context) => context.l10n.featActionsBody,
      how: (context) => context.l10n.featActionsHow,
      points: [
        (context) => context.l10n.featActionsPoint1,
        (context) => context.l10n.featActionsPoint2,
        (context) => context.l10n.featActionsPoint3,
      ],
    ),
    PremiumFeature(
      icon: Icons.view_agenda_outlined,
      title: (context) => context.l10n.featStitch,
      description: (context) => context.l10n.featStitchBody,
      how: (context) => context.l10n.featStitchHow,
      points: [
        (context) => context.l10n.featStitchPoint1,
        (context) => context.l10n.featStitchPoint2,
        (context) => context.l10n.featStitchPoint3,
      ],
    ),
    PremiumFeature(
      icon: Icons.content_copy_outlined,
      title: (context) => context.l10n.featDuplicates,
      description: (context) => context.l10n.featDuplicatesBody,
      how: (context) => context.l10n.featDuplicatesHow,
      points: [
        (context) => context.l10n.featDuplicatesPoint1,
        (context) => context.l10n.featDuplicatesPoint2,
        (context) => context.l10n.featDuplicatesPoint3,
      ],
    ),
    PremiumFeature(
      icon: Icons.create_new_folder_rounded,
      title: (context) => context.l10n.featUnlimited,
      // The one free-tier number, stated rather than alluded to. A paywall
      // that says "removes the caps" without saying what they were is asking
      // somebody to pay to find out.
      description: (context) => context.l10n.featUnlimitedBody(
        SubscriptionConstants.freeScreenshotLimit,
      ),
      // The one entry in this list whose ordinary line states a cap. Once the
      // cap is gone, so is the sentence.
      descriptionWhenPro: (context) => context.l10n.featUnlimitedBodyPro,
      how: (context) => context.l10n.featUnlimitedHow,
      points: [
        (context) => context.l10n.featUnlimitedPoint1,
        (context) => context.l10n.featUnlimitedPoint2,
        (context) => context.l10n.featUnlimitedPoint3,
      ],
    ),
  ];
}
