import 'package:flutter/material.dart';

/// The colours of the Shoto **mark** — and nothing else.
///
/// This is deliberately a separate file from [AppPalette] rather than six more
/// getters inside it, because the two obey different rules and mixing them
/// would quietly erode the one that matters.
///
/// `app_colors.dart` is achromatic on purpose: every neutral in it has
/// `R == G == B` exactly, and the only hues left in the interface are the
/// three that *mean* something. That rule exists because every screen in this
/// app is mostly other people's screenshots, and a tinted frame competes with
/// them.
///
/// **The mark is the one place that rule does not reach, and the reason is
/// what the mark competes against.** A tinted frame competes with the user's
/// screenshots; an app icon competes with forty other icons on a home screen,
/// and an achromatic one loses that fight without ever being noticed. The
/// restraint is correct inside the app and was costing us the only surface
/// where being noticed is the entire job.
///
/// ---
///
/// **The mark has been wrong twice, in opposite directions.**
///
/// It was first a glossy blue slab with a four-stop gradient, a rim light, a
/// moulded tray and three candy-coloured cards with a sun-and-hills picture on
/// the front one. Drawn well, and wrong: `PRODUCT.md` says the tone is
/// professional and never playful, it was a **folder** — the shape every file
/// app on the phone already owns, in the blue those apps are already painted —
/// and nothing about it appeared anywhere else in Shoto.
///
/// The correction over-corrected. Paper cards on near-black with two ruled
/// lines is a **document** icon: three cards and two lines of text is Docs, is
/// Notes, is Files, is Keep. The app's whole thesis is *screenshots* — which
/// are pictures — and the mark spent two years saying *paperwork*. It also
/// spent them saying nothing in colour at all.
///
/// ---
///
/// **What it is now: a bookmarked stack.** Three screenshots in the app's own
/// accent hue, and a ribbon on the front one. The ribbon is the whole idea —
/// *this is the one you kept* — and it is the only element here that is not a
/// step of a single hue, which is exactly why it reads first.
///
/// The values are still **fixed rather than mode-aware**: a brand mark that
/// changes with the system theme is not one mark, it is two, and neither of
/// them is the one on the store listing.
///
/// Nothing in this file may be used to paint a surface, a button, a chip or
/// any text. If a colour is needed for the interface it comes from
/// [AppPalette], which is where the reasoning about the interface lives.
abstract class AppBrand {
  AppBrand._();

  /// The ground the stack sits on, and the default slab.
  ///
  /// **Hue 178 — the app's own accent**, the same one `app_tint.dart` solves
  /// every interface accent from. That is the entire argument for teal over
  /// the six other palettes this was drawn in: it is not a new brand decision,
  /// it is the existing one finally reaching the icon. The thing on the home
  /// screen and the thing that opens now speak the same language.
  ///
  /// Flat, and flat is the argument: a gradient is how an icon says *I am an
  /// object with a surface*, and this one is a stack of pages, not a gadget.
  /// Every impression of depth in this mark comes from three solid steps of
  /// one hue, which is the only honest way to do it without a gradient and the
  /// only way that survives being flattened to a stencil.
  static const Color ground = Color(0xFF0E3B39);

  /// The filed one, in front. The single light shape in the mark, and the one
  /// the ribbon sits on.
  static const Color paper = Color(0xFFFAFAF7);

  /// The bookmark.
  ///
  /// **Fixed on every variant, and that is deliberate.** The slab colour
  /// changes across the five alternate icons — see [cardTones] — so the ribbon
  /// is the only element that is identical on all six. One constant is what
  /// makes six icons read as one product rather than as six logos, and this is
  /// the element a person actually remembers.
  static const Color ribbon = Color(0xFFFF6F5E);

  /// The two loose screenshots behind the filed one, as steps of [ground].
  ///
  /// **Derived rather than typed**, because the slab is a parameter: the five
  /// paid icon variants hand this a plum, an ember or a moss, and three
  /// hardcoded teals behind a plum slab would be three unrelated objects. The
  /// ramp has to be a function of whatever it is standing on.
  ///
  /// **The steps are relative, not absolute.** An earlier version solved for
  /// fixed lightness targets — 0.32 and 0.56, the two values the default was
  /// drawn at — and it collapsed on the variants: the tints are solved to
  /// luminance 0.085 and start at lightness 0.24, so the first card landed
  /// eight points above its own ground and disappeared. Adding a fixed
  /// *interval* keeps the same separation on any slab it is given.
  ///
  /// Saturation comes down as lightness goes up, which is what stops the ramp
  /// reading as three shades of paint and makes it read as one surface at
  /// three depths. It is also why this works in greyscale, on a store badge
  /// and under Android's themed icons: the three shapes were never separated
  /// by hue.
  static (Color back, Color mid) cardTones(Color slab) {
    final HSLColor base = HSLColor.fromColor(slab);

    HSLColor step(double lightness, double saturation) => base
        .withLightness((base.lightness + lightness).clamp(0.0, 0.9))
        .withSaturation((base.saturation * saturation).clamp(0.0, 1.0));

    return (step(0.185, 0.62).toColor(), step(0.420, 0.36).toColor());
  }
}
