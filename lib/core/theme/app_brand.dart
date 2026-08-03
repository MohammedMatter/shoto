import 'package:flutter/material.dart';

/// The colours of the SHOTO **mark** — and nothing else.
///
/// This is deliberately a separate file from [AppColors] rather than six more
/// getters inside it, because the two obey opposite rules and mixing them
/// would quietly erode the one that matters.
///
/// `app_colors.dart` is achromatic on purpose: every neutral in it has
/// `R == G == B` exactly, and the only hues left in the interface are the
/// three that *mean* something. That rule exists because every screen in this
/// app is mostly other people's screenshots, and a tinted frame competes with
/// them.
///
/// A logo is not a frame. It appears in exactly four places — the launcher
/// icon, the native launch window, the splash, and the two screens that
/// introduce the app (sign-in and the paywall) — and in all four its job is
/// the opposite of the interface's: to be recognisable at 48px on a home
/// screen full of other icons. That job needs colour, and it needs the *same*
/// colour every time regardless of theme.
///
/// So these values are **fixed, not mode-aware**. There is no `isDark`
/// anywhere below. A brand mark that changes colour with the system theme is
/// not one mark, it is two — and neither is the one on the App Store listing.
///
/// Nothing in this file may be used to paint a surface, a button, a chip or
/// any text. If a colour is needed for the interface it comes from
/// [AppColors], which is where the reasoning about the interface lives.
abstract class AppBrand {
  AppBrand._();

  // ------------------------------------------------------------- backdrop
  //
  // The rounded slab the mark sits on.

  static const Color backdropTop = Color(0xFF4E95FC);
  static const Color backdropMid = Color(0xFF2064F4);
  static const Color backdropLow = Color(0xFF0E3CC8);
  static const Color backdropDeep = Color(0xFF082A96);

  /// Lit from the upper-left, which is where every other icon on the home
  /// screen is lit from. An icon lit from elsewhere reads as tilted.
  ///
  /// Four stops, not two. A straight blend from the top blue to the bottom
  /// navy spends most of its length in a washed-out middle, and at icon size
  /// that middle *is* the icon. The two interior stops keep the blue saturated
  /// through the upper two thirds and put the whole fall-off in the last
  /// quarter, which is what gives the slab a lit top and a weighted base
  /// instead of an even wash.
  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.3, 1),
    colors: [backdropTop, backdropMid, backdropLow, backdropDeep],
    stops: [0.0, 0.34, 0.72, 1.0],
  );

  /// The lit edge running around the top of the slab.
  ///
  /// Every icon on a modern home screen has one — it is what stops a rounded
  /// rectangle from looking like a sticker — and it is the single cheapest
  /// thing that reads as "this object has a surface". Drawn as a stroke just
  /// inside the silhouette, fading out by the time it reaches the bottom
  /// corners, because a rim light that goes all the way round is not a rim
  /// light, it is a border.
  static const Color backdropRim = Color(0xFF9FCBFF);

  // ----------------------------------------------------------------- tray
  //
  // Two faces, and the gap between their values is the entire reason the
  // shape reads as a pocket rather than as a blue rectangle: the back wall is
  // darker than the backdrop behind it (so it recedes), the front face is
  // brighter than both (so it comes forward), and the cards are trapped
  // between them.

  /// The inside back wall, visible as a thin band above the front rim.
  static const Color trayBack = Color(0xFF092A93);

  static const Color trayFrontTop = Color(0xFF2A66F0);
  static const Color trayFrontBottom = Color(0xFF0B34B6);

  /// Darkens the tray's left and right walls.
  ///
  /// A single vertical gradient makes the front face read as a flat panel
  /// leaning back. Real curvature needs the *sides* to fall away too, so this
  /// is laid over the vertical one horizontally — opaque at both walls, gone
  /// by a third of the way in. The two together are what make the pocket read
  /// as round rather than as folded from card.
  static const Color trayEdgeShade = Color(0x33001C6E);

  static const LinearGradient trayFront = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [trayFrontTop, trayFrontBottom],
  );

  /// The lit edge along the top of the front face.
  ///
  /// This single hairline is what makes the tray read as having thickness.
  /// Without it the front face and the back wall meet at a hard colour change
  /// and the shape flattens into two stacked rectangles.
  static const Color trayRim = Color(0xFF8FC8FF);

  /// What one card casts on the one behind it.
  ///
  /// Kept very light — 18% — and this is the one place in the whole project
  /// where a shadow is allowed. `app_colors.dart` bans them outright and it is
  /// right to: a shadow under a *control* is decoration standing in for
  /// hierarchy the layout should already have. Here the shadow is not
  /// decoration, it is the only thing that says these three shapes are
  /// stacked at different depths rather than printed side by side, and at 48px
  /// there is no other way to say it.
  static const Color cardShadow = Color(0x2E0A1F4E);

  // ---------------------------------------------------------------- cards
  //
  // Three, and three is the count on purpose — two reads as a pair, four
  // reads as a stack you cannot count at a glance.
  //
  // Mint and coral carry no meaning; they exist so the front card reads as
  // *one of several* rather than as the only thing in the tray. They are the
  // only two hues in the mark that are not blue, which is why they are
  // desaturated well below the backdrop: at 48px two loud hues beside a loud
  // blue turn the icon into confetti.

  static const Color cardMint = Color(0xFFB5E8DE);
  static const Color cardCoral = Color(0xFFFB6A72);
  static const Color cardPaper = Color(0xFFF7F8FC);

  /// The picture inside the front card.
  static const Color photo = Color(0xFF6E9BF7);

  /// The hills in that picture — one step down from [photo], not a different
  /// colour. A second hue inside a shape this small is illegible.
  static const Color photoDeep = Color(0xFF1E4FD6);

  static const Color photoSun = Color(0xFFD2DFFB);
}
