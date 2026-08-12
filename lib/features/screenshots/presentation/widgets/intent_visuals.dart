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
    ScreenshotIntent.watch => context.l10n.intentWatch,
    ScreenshotIntent.listen => context.l10n.intentListen,
    ScreenshotIntent.cook => context.l10n.intentCook,
    ScreenshotIntent.book => context.l10n.intentBook,
    ScreenshotIntent.pay => context.l10n.intentPay,
    ScreenshotIntent.send => context.l10n.intentSend,
    ScreenshotIntent.download => context.l10n.intentDownload,
    ScreenshotIntent.apply => context.l10n.intentApply,
    ScreenshotIntent.compare => context.l10n.intentCompare,
    ScreenshotIntent.fix => context.l10n.intentFix,
  };

  /// The heading of the list of everything still waiting under this intent.
  String waitingTitle(BuildContext context) => switch (this) {
    ScreenshotIntent.buy => context.l10n.intentBuyWaiting,
    ScreenshotIntent.read => context.l10n.intentReadWaiting,
    ScreenshotIntent.reply => context.l10n.intentReplyWaiting,
    ScreenshotIntent.tryIt => context.l10n.intentTryWaiting,
    ScreenshotIntent.visit => context.l10n.intentVisitWaiting,
    ScreenshotIntent.watch => context.l10n.intentWatchWaiting,
    ScreenshotIntent.listen => context.l10n.intentListenWaiting,
    ScreenshotIntent.cook => context.l10n.intentCookWaiting,
    ScreenshotIntent.book => context.l10n.intentBookWaiting,
    ScreenshotIntent.pay => context.l10n.intentPayWaiting,
    ScreenshotIntent.send => context.l10n.intentSendWaiting,
    ScreenshotIntent.download => context.l10n.intentDownloadWaiting,
    ScreenshotIntent.apply => context.l10n.intentApplyWaiting,
    ScreenshotIntent.compare => context.l10n.intentCompareWaiting,
    ScreenshotIntent.fix => context.l10n.intentFixWaiting,
  };

  IconData get icon => switch (this) {
    ScreenshotIntent.buy => Icons.shopping_bag_rounded,
    ScreenshotIntent.read => Icons.menu_book_rounded,
    ScreenshotIntent.reply => Icons.reply_rounded,
    ScreenshotIntent.tryIt => Icons.science_rounded,
    ScreenshotIntent.visit => Icons.place_rounded,
    ScreenshotIntent.watch => Icons.play_circle_outline_rounded,
    ScreenshotIntent.listen => Icons.headphones_rounded,
    ScreenshotIntent.cook => Icons.restaurant_rounded,
    ScreenshotIntent.book => Icons.event_available_rounded,
    ScreenshotIntent.pay => Icons.receipt_long_rounded,
    ScreenshotIntent.send => Icons.send_rounded,
    ScreenshotIntent.download => Icons.download_rounded,
    ScreenshotIntent.apply => Icons.assignment_turned_in_rounded,
    ScreenshotIntent.compare => Icons.compare_arrows_rounded,
    ScreenshotIntent.fix => Icons.build_rounded,
  };

  /// **Deliberately no per-intent colour.**
  ///
  /// The obvious design is a hue per intent, and it is wrong for this app.
  /// `AppPalette` is down to three hues on purpose and says why: with the
  /// accent and every neutral achromatic, the surviving colours "are legible
  /// as meaning rather than as decoration". Spending a palette on identity
  /// would undo that everywhere, not just here — once the library has a dozen
  /// tinted chip families, rose stops reading as *dangerous* and teal stops
  /// reading as *organise*. It only got more true as the list grew: fifteen
  /// hues are not fifteen meanings, they are noise.
  ///
  /// Short verbs with distinct glyphs are already unmistakable at a glance,
  /// which is all the row has to be. Colour is kept for the one thing in this
  /// feature that is genuinely a state rather than a name: waiting versus
  /// done.
  Color tint(BuildContext context) => context.colors.secondary;
}

/// The same three questions, asked of any intent at all.
///
/// Every widget in the feature reads intents through this and never through
/// the enum extension above, which is what keeps a user-authored verb from
/// being second-class: nothing downstream can tell, or needs to.
extension IntentRefVisuals on IntentRef {
  String label(BuildContext context) => switch (this) {
    BuiltInIntent(:final ScreenshotIntent intent) => intent.label(context),
    // The user's own words, in the language they typed them. Never localized.
    CustomIntent(:final String label) => label,
  };

  /// The heading over everything still waiting under this intent.
  ///
  /// A custom intent reuses its plain label. The built-ins get a second
  /// translated string ("To buy") because a heading is a different sentence
  /// from a button, but inventing that grammar for a phrase the user wrote —
  /// prefixing it, conjugating it — would mangle the very thing they typed.
  String waitingTitle(BuildContext context) => switch (this) {
    BuiltInIntent(:final ScreenshotIntent intent) => intent.waitingTitle(
      context,
    ),
    CustomIntent(:final String label) => label,
  };

  IconData get icon => switch (this) {
    BuiltInIntent(:final ScreenshotIntent intent) => intent.icon,
    CustomIntent(:final String iconKey) => IntentIcons.resolve(iconKey),
  };

  /// The same one hue for every intent, built-in or invented — see
  /// [IntentVisuals.tint] for why there is no palette per verb.
  ///
  /// It lives here as well as on the enum because of the rule at the top of
  /// this extension: widgets read intents through [IntentRef] and never through
  /// [ScreenshotIntent], and a widget that had to unwrap the ref to find out
  /// what colour to use would be the first exception to that — for a colour
  /// that is the same either way.
  Color tint(BuildContext context) => context.colors.secondary;
}

/// The glyphs a user-authored intent can be given.
///
/// A closed set, keyed by name. Two reasons it is not an open icon picker over
/// the whole Material font: the key is written into the database, so it has to
/// mean the same thing after an app update — and a non-constant `IconData`
/// defeats tree-shaking, which would ship the entire icon font to every user
/// so that a handful of them could pick a rocket.
abstract final class IntentIcons {
  /// **Grouped by subject, in reading order, and never reordered.**
  ///
  /// A grid of fifty glyphs in arbitrary order is a search problem; the same
  /// fifty with money beside money and places beside places is a glance. The
  /// grid deliberately carries no group headings — the grouping is doing its
  /// work through adjacency, and labelling it would add six translations and a
  /// row of chrome to something the eye already sorted.
  ///
  /// **Keys are permanent.** Each one is written into a database row, so a key
  /// may be added and its position moved, but the glyph a key points at must
  /// not change: somebody's "return it" would silently become a different
  /// picture. Adding to the end of a group is always safe.
  static const Map<String, IconData> byKey = <String, IconData>{
    // Marks and priorities — the ones wanted most often, first.
    'flag': Icons.flag_rounded,
    'star': Icons.star_rounded,
    'bolt': Icons.bolt_rounded,
    'heart': Icons.favorite_rounded,
    'idea': Icons.lightbulb_rounded,
    'clock': Icons.schedule_rounded,
    'alarm': Icons.alarm_rounded,
    'calendar': Icons.event_rounded,
    'check': Icons.task_alt_rounded,
    'warning': Icons.priority_high_rounded,
    // People and messages.
    'call': Icons.call_rounded,
    'mail': Icons.mail_rounded,
    'chat': Icons.chat_bubble_rounded,
    'people': Icons.people_alt_rounded,
    'person': Icons.person_rounded,
    'baby': Icons.child_care_rounded,
    'pet': Icons.pets_rounded,
    'gift': Icons.card_giftcard_rounded,
    'cake': Icons.cake_rounded,
    'celebrate': Icons.celebration_rounded,
    // Money and buying.
    'money': Icons.payments_rounded,
    'cart': Icons.shopping_cart_rounded,
    'bag': Icons.shopping_bag_rounded,
    'card': Icons.credit_card_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'receipt': Icons.receipt_long_rounded,
    'tag': Icons.sell_rounded,
    'store': Icons.storefront_rounded,
    'bank': Icons.account_balance_rounded,
    'chart': Icons.insights_rounded,
    // Work and study.
    'work': Icons.work_rounded,
    'school': Icons.school_rounded,
    'book': Icons.menu_book_rounded,
    'doc': Icons.description_rounded,
    'edit': Icons.edit_rounded,
    'folder': Icons.folder_rounded,
    'link': Icons.link_rounded,
    'code': Icons.code_rounded,
    'science': Icons.science_rounded,
    'target': Icons.track_changes_rounded,
    // Places and getting there.
    'home': Icons.home_rounded,
    'car': Icons.directions_car_rounded,
    'travel': Icons.flight_rounded,
    'train': Icons.train_rounded,
    'bike': Icons.pedal_bike_rounded,
    'map': Icons.map_rounded,
    'place': Icons.place_rounded,
    'beach': Icons.beach_access_rounded,
    'hotel': Icons.hotel_rounded,
    'key': Icons.vpn_key_rounded,
    // Living.
    'fitness': Icons.fitness_center_rounded,
    'health': Icons.medical_services_rounded,
    'food': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'plant': Icons.local_florist_rounded,
    'music': Icons.music_note_rounded,
    'movie': Icons.movie_rounded,
    'game': Icons.sports_esports_rounded,
    'camera': Icons.photo_camera_rounded,
    'tool': Icons.handyman_rounded,
  };

  /// The default, and what an unknown key falls back to.
  ///
  /// Unknown is a real case rather than a defensive one: a key written by a
  /// newer build lands in an older app's database the moment a backup is
  /// restored, and a missing glyph must not take the row down with it.
  static const IconData fallback = Icons.flag_rounded;

  static List<String> get keys => byKey.keys.toList();

  static IconData resolve(String key) => byKey[key] ?? fallback;
}
