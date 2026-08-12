import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// The glyphs a folder can be given.
///
/// Built to the same rules as `IntentIcons`, and for the same two reasons: the
/// key is written into a database row, so it has to mean the same thing after
/// an app update — and a non-constant [IconData] defeats tree-shaking, which
/// would ship two entire icon fonts to every user so that a handful of them
/// could pick a rocket.
///
/// ---
///
/// **Why a folder needs a glyph at all, when the intent picker's own notes
/// argue against per-item colour.**
///
/// A folder is not an intent. Intents are fifteen short verbs in a row and a
/// word is the fastest thing to read there. A folder is a tile in a grid, seen
/// from arm's length, and its name is the one thing that does *not* fit: three
/// columns of tiles leave room for about eleven characters. "Medications" and
/// "Meditation" are the same word at that width. A glyph is what survives the
/// crop.
abstract final class FolderIcons {
  /// **Grouped by subject, in reading order, and never reordered.**
  ///
  /// The grid carries no group headings — adjacency is doing the sorting, and
  /// labelling it would add eight translations and a row of chrome to
  /// something the eye already solved. Same call as the intent picker.
  ///
  /// **Keys are permanent.** Each one is written into a `folders.icon_key`
  /// cell, so a key may be added and its position moved, but the glyph a key
  /// points at must not change: somebody's "Recipes" would silently become a
  /// different picture. Adding to the end of a group is always safe.
  static const Map<String, IconData> byKey = <String, IconData>{
    // Filing itself — the plain answers, first, because most folders are one
    // of these and nobody should have to hunt for "folder".
    'folder': Icons.folder_rounded,
    'star': Icons.star_rounded,
    'heart': Icons.favorite_rounded,
    'bookmark': Icons.bookmark_rounded,
    'flag': Icons.flag_rounded,
    'idea': Icons.lightbulb_rounded,
    'sparkle': Icons.auto_awesome_rounded,
    'magic': Icons.auto_fix_high_rounded,
    // Documents and work.
    'doc': Icons.description_rounded,
    'note': Icons.sticky_note_2_rounded,
    'book': Icons.menu_book_rounded,
    'school': Icons.school_rounded,
    'work': Icons.work_rounded,
    'brain': Icons.psychology_rounded,
    'code': Icons.code_rounded,
    'link': Icons.link_rounded,
    'ruler': Icons.straighten_rounded,
    'scissors': Icons.content_cut_rounded,
    // Money.
    'money': Icons.payments_rounded,
    'card': Icons.credit_card_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'receipt': Icons.receipt_long_rounded,
    'bank': Icons.account_balance_rounded,
    'cart': Icons.shopping_cart_rounded,
    'bag': Icons.shopping_bag_rounded,
    'tag': Icons.sell_rounded,
    'store': Icons.storefront_rounded,
    'chart': Icons.insights_rounded,
    // Going places.
    'map': Icons.map_rounded,
    'place': Icons.place_rounded,
    'flight': Icons.flight_rounded,
    'car': Icons.directions_car_rounded,
    'train': Icons.train_rounded,
    'bike': Icons.pedal_bike_rounded,
    'hotel': Icons.hotel_rounded,
    'beach': Icons.beach_access_rounded,
    'building': Icons.apartment_rounded,
    'luggage': Icons.luggage_rounded,
    // Body and home.
    'health': Icons.medical_services_rounded,
    'pill': Icons.medication_rounded,
    'fitness': Icons.fitness_center_rounded,
    'run': Icons.directions_run_rounded,
    'food': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'home': Icons.home_rounded,
    'bed': Icons.bed_rounded,
    'pet': Icons.pets_rounded,
    'plant': Icons.local_florist_rounded,
    'tree': Icons.park_rounded,
    'leaf': Icons.eco_rounded,
    // Watching and listening.
    'music': Icons.music_note_rounded,
    'headphones': Icons.headphones_rounded,
    'play': Icons.play_arrow_rounded,
    'film': Icons.movie_rounded,
    'ticket': Icons.local_activity_rounded,
    'mic': Icons.mic_rounded,
    'theatre': Icons.theater_comedy_rounded,
    'game': Icons.sports_esports_rounded,
    'camera': Icons.photo_camera_rounded,
    'screen': Icons.desktop_windows_rounded,
    // People and time.
    'person': Icons.person_rounded,
    'people': Icons.people_alt_rounded,
    'chat': Icons.chat_bubble_rounded,
    'mail': Icons.mail_rounded,
    'call': Icons.call_rounded,
    'gift': Icons.card_giftcard_rounded,
    'cake': Icons.cake_rounded,
    'calendar': Icons.event_rounded,
    'clock': Icons.schedule_rounded,
    'bell': Icons.notifications_rounded,
    // Marks and weather — the small vocabulary of "this one, not that one".
    'trophy': Icons.emoji_events_rounded,
    'medal': Icons.workspace_premium_rounded,
    'fire': Icons.local_fire_department_rounded,
    'bolt': Icons.bolt_rounded,
    'megaphone': Icons.campaign_rounded,
    'cloud': Icons.cloud_rounded,
    'moon': Icons.nightlight_round,
    'sun': Icons.wb_sunny_rounded,
    'snow': Icons.ac_unit_rounded,
    'key': Icons.vpn_key_rounded,
  };

  /// ------------------------------------------------------------- the apps
  ///
  /// **The one group that is specific to this app rather than borrowed from
  /// the intent picker.**
  ///
  /// Everything in Shoto arrived as a screenshot *of something*, and the single
  /// most common way people describe a pile of screenshots is by where they
  /// came from: the Instagram ones, the WhatsApp ones, the receipts from the
  /// bank app. A folder named "Instagram" wearing a camera glyph is describing
  /// itself twice and recognising itself never.
  ///
  /// Brand marks rather than app icons: these are the trademark glyphs from
  /// Font Awesome's free brands set — a shape, in the folder's own colour, not
  /// a coloured logo pasted onto the page. That is both the licensable form and
  /// the one that fits a palette which has spent seven revisions keeping other
  /// people's colours out of the interface.
  ///
  /// **A second map, because they are a second type.** Font Awesome 11 wraps
  /// its glyphs in `FaIconData` specifically to keep them out of Material's
  /// `Icon`, which boxes everything into a square — and several of these are
  /// not square (YouTube's mark is 576 units wide against 512 tall), so an
  /// `Icon` would clip them. Unwrapping to `.data` to get one flat map is not
  /// available either: reading a field off a constant is not itself a constant
  /// expression in Dart, and a non-`const` map of `IconData` fails the release
  /// build outright under `--tree-shake-icons`.
  ///
  /// [FolderGlyph] is what hides the split from every call site.
  static const Map<String, FaIconData> brandsByKey = <String, FaIconData>{
    'whatsapp': FontAwesomeIcons.whatsapp,
    'instagram': FontAwesomeIcons.instagram,
    'telegram': FontAwesomeIcons.telegram,
    'x': FontAwesomeIcons.xTwitter,
    'facebook': FontAwesomeIcons.facebook,
    'youtube': FontAwesomeIcons.youtube,
    'tiktok': FontAwesomeIcons.tiktok,
    'snapchat': FontAwesomeIcons.snapchat,
    'linkedin': FontAwesomeIcons.linkedin,
    'reddit': FontAwesomeIcons.reddit,
    'pinterest': FontAwesomeIcons.pinterest,
    'discord': FontAwesomeIcons.discord,
    'twitch': FontAwesomeIcons.twitch,
    'spotify': FontAwesomeIcons.spotify,
    'github': FontAwesomeIcons.github,
    'apple': FontAwesomeIcons.apple,
    'google': FontAwesomeIcons.google,
    'amazon': FontAwesomeIcons.amazon,
  };

  /// The default, and what an unknown key falls back to.
  ///
  /// Unknown is a real case rather than a defensive one, and here it has a
  /// second source on top of the restored-backup one the intent picker names:
  /// every folder that existed *before* this column did has no key at all.
  /// They get the plain folder, which is exactly what they were drawn with.
  static const IconData fallback = Icons.folder_rounded;

  /// Every key the picker offers, subjects first and apps last.
  static List<String> get keys => <String>[...byKey.keys, ...brandsByKey.keys];

  static IconData resolve(String? key) =>
      key == null ? fallback : byKey[key] ?? fallback;

  /// The brand mark for [key], or null when the key is an ordinary glyph.
  static FaIconData? brand(String? key) =>
      key == null ? null : brandsByKey[key];
}

/// A folder's glyph, whichever of the two fonts it came out of.
///
/// Exists so that no call site has to know the catalog is split in two — the
/// card, the picker and the actions sheet all just want "the picture for this
/// key at this size in this colour".
class FolderGlyph extends StatelessWidget {
  final String? iconKey;
  final double size;
  final Color color;

  const FolderGlyph({
    super.key,
    required this.iconKey,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final FaIconData? brand = FolderIcons.brand(iconKey);
    if (brand != null) {
      return FaIcon(brand, size: size, color: color);
    }
    return Icon(FolderIcons.resolve(iconKey), size: size, color: color);
  }
}
