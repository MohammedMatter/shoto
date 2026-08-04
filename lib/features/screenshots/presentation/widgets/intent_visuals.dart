import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';

/// How each intent looks and reads.
///
/// An extension in the presentation layer rather than fields on the enum,
/// following `content_trait_visuals.dart` — the enum is stored in a database
/// and read by pure Dart, so it must not carry a `BuildContext` or a `Color`.
extension IntentVisuals on ScreenshotIntent {
  /// The verb, in the imperative. **"Buy" and not "Shopping".**
  ///
  /// A noun turns this straight back into a folder, which is the thing it
  /// exists not to be: "Shopping" is a place a screenshot lives, "Buy" is
  /// something you have not done yet.
  String label(BuildContext context) => switch (this) {
    ScreenshotIntent.buy => context.l10n.intentBuy,
    ScreenshotIntent.read => context.l10n.intentRead,
    ScreenshotIntent.reply => context.l10n.intentReply,
    ScreenshotIntent.tryIt => context.l10n.intentTry,
    ScreenshotIntent.visit => context.l10n.intentVisit,
  };

  /// The heading of the list of everything still waiting under this intent.
  String waitingTitle(BuildContext context) => switch (this) {
    ScreenshotIntent.buy => context.l10n.intentBuyWaiting,
    ScreenshotIntent.read => context.l10n.intentReadWaiting,
    ScreenshotIntent.reply => context.l10n.intentReplyWaiting,
    ScreenshotIntent.tryIt => context.l10n.intentTryWaiting,
    ScreenshotIntent.visit => context.l10n.intentVisitWaiting,
  };

  IconData get icon => switch (this) {
    ScreenshotIntent.buy => Icons.shopping_bag_rounded,
    ScreenshotIntent.read => Icons.menu_book_rounded,
    ScreenshotIntent.reply => Icons.reply_rounded,
    ScreenshotIntent.tryIt => Icons.science_rounded,
    ScreenshotIntent.visit => Icons.place_rounded,
  };

  /// **Deliberately no per-intent colour.**
  ///
  /// The obvious design is five hues, one per intent, and it is wrong for this
  /// app. `AppColors` is down to three hues on purpose and says why: with the
  /// accent and every neutral achromatic, the surviving colours "are legible
  /// as meaning rather than as decoration". Spending five on identity would
  /// undo that everywhere, not just here — once the library has five tinted
  /// chip families, rose stops reading as *dangerous* and teal stops reading
  /// as *organise*.
  ///
  /// Five short verbs with five distinct glyphs are already unmistakable at a
  /// glance, which is all the row has to be. Colour is kept for the one thing
  /// in this feature that is genuinely a state rather than a name: waiting
  /// versus done.
  Color get tint => AppColors.secondary;
}
