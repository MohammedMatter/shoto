import 'package:flutter/material.dart';

/// The colours of the SHOTO **mark** — and nothing else.
///
/// This is deliberately a separate file from [AppColors] rather than six more
/// getters inside it, because the two obey different rules and mixing them
/// would quietly erode the one that matters.
///
/// `app_colors.dart` is achromatic on purpose: every neutral in it has
/// `R == G == B` exactly, and the only hues left in the interface are the
/// three that *mean* something. That rule exists because every screen in this
/// app is mostly other people's screenshots, and a tinted frame competes with
/// them.
///
/// ---
///
/// **The mark used to break that rule, and it was the most visible thing in
/// the project.**
///
/// It was a glossy blue slab with a four-stop gradient, a rim light, a
/// moulded tray and three candy-coloured cards — mint, coral, paper — with a
/// little sun-and-hills picture on the front one. Drawn well, and wrong:
///
/// * `PRODUCT.md` says the tone is professional and never playful, and
///   records that a mascot was rejected for exactly that reason. Then the one
///   asset every store visitor and every home screen sees was the most
///   playful thing in the repo.
/// * It was a **folder**, which is the shape every file app on the phone
///   already owns, in the blue those apps are already painted.
/// * It looked like a different product's icon. Nothing about it appeared
///   anywhere else in SHOTO: not the palette, not the shapes, not the
///   restraint.
///
/// So the mark is now the same thing the app draws for itself — paper on ink,
/// and the clipped corner. The values below are still **fixed rather than
/// mode-aware**: a brand mark that changes with the system theme is not one
/// mark, it is two, and neither of them is the one on the store listing.
///
/// Nothing in this file may be used to paint a surface, a button, a chip or
/// any text. If a colour is needed for the interface it comes from
/// [AppColors], which is where the reasoning about the interface lives.
abstract class AppBrand {
  AppBrand._();

  /// The slab. Flat, and flat is the argument: a gradient is how an icon says
  /// *I am an object with a surface*, and this one is a page, not a gadget.
  ///
  /// It matches the app's own dark background rather than being picked for
  /// the icon, so the thing on the home screen and the thing that opens are
  /// the same colour.
  static const Color ink = Color(0xFF121212);

  // ---------------------------------------------------------------- cards
  //
  // Three, and three is the count on purpose — two reads as a pair, four
  // reads as a stack you cannot count at a glance.
  //
  // They are separated by *value* rather than by hue, which is the whole
  // reason this survives Android's themed icons, a greyscale store badge and
  // a 48px launcher: the mark never depended on colour to be legible, so
  // taking its colour away costs it nothing.

  /// The filed one, in front, wearing the cut corner.
  static const Color paper = Color(0xFFFAFAF7);

  static const Color paperMid = Color(0xFFD8D8D3);
  static const Color paperBack = Color(0xFFA9A9A3);

  /// The two short rules printed on the front card.
  ///
  /// Not decoration and not a picture: they are what makes the shape read as
  /// *a screenshot with something written in it* rather than as a blank card,
  /// which is the one claim the mark needs to make. Ink, so they are the same
  /// substance as the slab showing through the cut corner.
  static const Color rule = Color(0xFF121212);

  /// What the front card casts on the two behind it.
  ///
  /// Kept very light and this is the one place in the whole project where a
  /// shadow is allowed. `app_colors.dart` bans them outright and it is right
  /// to: a shadow under a *control* is decoration standing in for hierarchy
  /// the layout should already have. Here it is the only thing that says
  /// these three shapes are stacked at different depths rather than printed
  /// side by side, and at 48px there is no other way to say it.
  static const Color cardShadow = Color(0x33000000);
}
