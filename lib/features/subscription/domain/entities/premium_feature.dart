import 'package:flutter/material.dart';
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
  });

  static final List<PremiumFeature> all = [
    // First because it is the one that changes what using SHOTO is like:
    // everything else here helps you handle a screenshot once you've found
    // it, while this stops the filing being your job at all.
    PremiumFeature(
      icon: Icons.rule_folder_rounded,
      title: (context) => context.l10n.featRules,
      description: (context) => context.l10n.featRulesBody,
      how: (context) => context.l10n.featRulesHow,
      points: [
        (context) => context.l10n.featRulesPoint1,
        (context) => context.l10n.featRulesPoint2,
        (context) => context.l10n.featRulesPoint3,
      ],
    ),
    PremiumFeature(
      icon: Icons.manage_search_rounded,
      title: (context) => context.l10n.featSearch,
      description: (context) => context.l10n.featSearchBody,
      how: (context) => context.l10n.featSearchHow,
      points: [
        (context) => context.l10n.featSearchPoint1,
        (context) => context.l10n.featSearchPoint2,
        (context) => context.l10n.featSearchPoint3,
      ],
    ),
    PremiumFeature(
      icon: Icons.shield_moon_rounded,
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
      icon: Icons.photo_size_select_large_rounded,
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
      icon: Icons.content_copy_rounded,
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
      description: (context) => context.l10n.featUnlimitedBody,
      how: (context) => context.l10n.featUnlimitedHow,
      points: [
        (context) => context.l10n.featUnlimitedPoint1,
        (context) => context.l10n.featUnlimitedPoint2,
        (context) => context.l10n.featUnlimitedPoint3,
      ],
    ),
  ];
}
