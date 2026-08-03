import 'package:flutter/material.dart';

/// Every color in the app is read through these getters instead of plain
/// `static const` values, so the whole custom widget set (which reads
/// `AppColors.x` directly rather than `Theme.of(context)`) can react to
/// light/dark mode without every widget needing to know about `Theme`.
///
/// [setBrightness] must be called once per frame, synchronously, before any
/// widget below it builds — [MyApp] does this at the very top of its
/// `build()` method, ahead of constructing the rest of the tree. Because
/// Flutter builds a frame depth-first and synchronously, every descendant
/// widget built afterwards during that same frame sees the correct value.
///
/// ---
///
/// Palette: **"Charcoal"** — warm neutrals, an achromatic accent, three
/// semantic hues.
///
/// The reasoning is specific to SHOTO rather than to taste. Every screen in
/// this app is mostly *other apps' screenshots*: a receipt, a chat, a poster,
/// a design reference — hundreds of colours SHOTO does not choose and cannot
/// predict. So the interface stays quiet and the pictures stay loud.
///
/// Quiet is not the same as colourless, and this file has been to both
/// extremes to find that out. It shipped a `#3355FF → #7C5CFF → #FF7A5C`
/// gradient across twenty-two surfaces, which is the house style of every
/// generated UI on the internet. It was then stripped back to a single
/// ultramarine, which measured 100% saturation and carried the same
/// fingerprint on its own. It was then stripped to nothing at all, which read
/// as unfinished rather than as restrained.
///
/// What works is a small system where **every colour is doing a job**:
///
/// * [marker] — charcoal. Filled buttons, the active tab, a selected chip.
/// * [secondary] — teal. Informational, non-destructive: moving a file.
/// * [success] — sage. Something completed.
/// * [alert] — red. Destructive, and nothing else.
///
/// The accent carries no hue at all, so the only colours left in the
/// interface are the three that *mean* something. Anything with no job stays
/// neutral: a tool icon is not tinted because nothing about "safe share" is
/// teal, and colour that encodes nothing is noise.
abstract class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.dark;

  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _brightness == Brightness.dark;

  // ------------------------------------------------------------- the six
  //
  // **Every neutral here is achromatic: R == G == B, exactly.**
  //
  // This file has now run a cool ramp (blue-black — the default look of every
  // generated dark UI) and a warm one (red the highest channel by two or
  // three points, meant to read as paper and pencil). The warm ramp was the
  // better idea and still the wrong one *at this size*: three points of red
  // is invisible on a chip and unmistakable across a whole screen, so the app
  // read brown. A cast nobody asked for, on every surface standing behind
  // other people's screenshots.
  //
  // A tint is a decision, and applied to the canvas it is a decision made
  // hundreds of times per screen and justified nowhere. Equal channels means
  // the only colour in this app is colour something put there on purpose.

  /// Text on paper; the canvas in dark mode.
  static const Color ink = Color(0xFF1A1A1A);

  /// The canvas in light mode; text in dark mode. Off-white rather than a
  /// pure `#FFFFFF`, so a white card still has somewhere to sit above it —
  /// but with no hue in it at all.
  static const Color paper = Color(0xFFFAFAFA);

  /// Secondary text, both modes. One value that works on either because it
  /// sits at the midpoint — fewer values, fewer chances to drift.
  static const Color graphite = Color(0xFF737373);

  /// **The accent: charcoal.** `#26221F` on light, `#EDE9E2` on dark.
  ///
  /// The history above is five attempts at this one value — highlighter
  /// yellow, petrol green, ultramarine, nothing at all, then brass. Brass was
  /// a defensible colour and still the wrong one *here*: it put a copper cast
  /// on every filled button, tab and chip in an app whose content is other
  /// people's screenshots, so the frame had a temperature the pictures inside
  /// it did not share.
  ///
  /// **Charcoal rather than a mid grey**, and that choice is not a matter of
  /// taste. A mid grey fill is the universal language of *disabled* — the
  /// primary button on every platform greys out when it stops working. Fill a
  /// live button with `#4A4642` and it reads as switched off no matter how
  /// correct the label is. Near-black reads as ink: deliberate, on, pressed
  /// into the paper. The accent needs the second meaning, so it sits as close
  /// to black as it can while staying distinguishable from the text.
  ///
  /// Which is the other half of the value: light-mode charcoal is
  /// deliberately a few points *softer* than [ink]. Body text stays the
  /// darkest thing on the page, so a filled control never out-weighs the
  /// words it is there to support.
  ///
  /// The dark value is not the light one lightened, it is its opposite.
  /// Charcoal on a near-black canvas is invisible, so in dark mode the accent
  /// inverts to bone and [onPrimary] inverts with it — the same relationship
  /// (a near-canvas-opposite slab carrying near-canvas text), mirrored. This
  /// is the rule an earlier yellow accent broke and was replaced for: an
  /// accent you cannot use in both modes is not an accent.
  ///
  /// Saturation is now zero rather than "under the ceiling", and the warmth
  /// that used to come from the accent comes from the neutrals themselves —
  /// red is still the highest channel in both values, so the greys read as
  /// paper and pencil rather than as a screen.
  static Color get marker =>
      isDark ? const Color(0xFFEBEBEB) : const Color(0xFF262626);

  /// Destructive only, and mode-aware — a single red dark enough to read on
  /// paper turns muddy on near-black, which is the same trap the accent fell
  /// into.
  static Color get alert =>
      isDark ? const Color(0xFFF0645F) : const Color(0xFFC4342C);

  // ------------------------------------------------------------- surfaces
  //
  // Three steps above the canvas in each mode, spaced far enough apart that a
  // card reads as raised without leaning on a shadow — shadows barely
  // register on near-black, so the separation has to come from the value.

  static Color get background => isDark ? ink : paper;

  /// Cards and sheets. In dark mode lighter than the background so elevation
  /// reads without shadows, which barely register on near-black.
  static Color get surface =>
      isDark ? const Color(0xFF212121) : const Color(0xFFFFFFFF);

  static Color get surfaceVariant =>
      isDark ? const Color(0xFF292929) : const Color(0xFFF0F0F0);

  /// A third step, for chips and inputs sitting *on* a surface where
  /// [surfaceVariant] would disappear against it.
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF333333) : const Color(0xFFE7E7E7);

  static Color get border =>
      isDark ? const Color(0xFF303030) : const Color(0xFFE2E2E2);

  static Color get textPrimary => isDark ? paper : ink;

  static Color get textSecondary => isDark ? const Color(0xFF9E9E9E) : graphite;

  static Color get textDisabled =>
      isDark ? const Color(0xFF6B6B6B) : const Color(0xFFABABAB);

  // ------------------------------------------------------ semantic hues
  //
  // Three hues besides the accent, and each one earns its place by meaning
  // something a word would otherwise have to carry: this is done, this is
  // information, this is destructive. Each stays under 80% saturation and is
  // split across the two modes so it sits correctly against its own canvas.
  //
  // These are the *only* three hues left in the app now that the accent and
  // every neutral are colourless, which is what makes them legible as
  // meaning rather than as decoration.

  /// Filled buttons, active tabs, selected chips. The accent.
  static Color get primary => marker;

  /// One step *toward* the canvas from [marker] — a pressed or secondary
  /// version of the accent, not a darker one. With an achromatic accent
  /// "darker" is meaningless in dark mode, where the accent is already the
  /// light end.
  static Color get primaryVariant =>
      isDark ? const Color(0xFFCACACA) : const Color(0xFF3D3D3D);

  /// Informational, non-destructive actions — moving a file, a suggested
  /// match. Teal because it is the one cool hue far enough from both the
  /// accent and the alert to never be confused with either.
  static Color get secondary =>
      isDark ? const Color(0xFF63B8B0) : const Color(0xFF2A7A72);

  static Color get secondaryVariant =>
      isDark ? const Color(0xFF4A9891) : const Color(0xFF1F5F59);

  static Color get error => alert;

  /// Completion. Sage rather than a signal green: this app confirms filing,
  /// not payment, and a saturated green would outrank the accent every time
  /// it appeared.
  static Color get success =>
      isDark ? const Color(0xFF93B36B) : const Color(0xFF55742F);

  static Color get warning => marker;

  /// Used for scrims over imagery, so it stays dark in both modes.
  static const Color overlay = Color(0xFF141414);

  /// Text and icons that sit **on** [marker], which is [primary].
  static Color get onMarker => onPrimary;

  static Color get onPrimary => isDark ? ink : paper;

  // ------------------------------------------------------------ gradients
  //
  // These are all flat now.
  //
  // They stay as LinearGradients rather than being deleted because they are
  // referenced in twenty-two places, and a two-stop gradient between one
  // colour and itself costs nothing and renders identically to a fill. The
  // blue→violet→coral sweep they used to carry is gone for good.

  static LinearGradient get primaryGradient =>
      LinearGradient(colors: [primary, primary]);

  static LinearGradient get secondaryGradient =>
      LinearGradient(colors: [marker, marker]);

  static LinearGradient get brandGradient =>
      LinearGradient(colors: [marker, marker]);

  static LinearGradient get scrimGradient => LinearGradient(
    colors: [background.withValues(alpha: 0), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ------------------------------------------------------------- no shadows
  //
  // There is no shadow token here, and no `boxShadow` anywhere in the app.
  //
  // There used to be a `cardShadow`, on ten surfaces: cards, buttons, the
  // logo, the quick-save panel. It was already written down as "near-absent on
  // purpose", and it was neither — the dark value was black at 35% over an 18px
  // blur, sitting on a `#1A1A1A` canvas. A soft dark shape on a nearly-black
  // background does not read as depth, because there is nothing left to darken;
  // it reads as a smudge around the card, and at eighteen pixels it is wide
  // enough to see as a distinct grey halo with its own edge. Every card in the
  // library had one, which is what made it obvious: not one shadow, a grid of
  // them.
  //
  // The light-mode value went with it rather than being kept. A 5% shadow on
  // paper is genuinely almost invisible, so it was buying nothing except a
  // second, mode-dependent story about where depth comes from — and this
  // palette already answers that: the [border] and the step from [background]
  // to [surface] to [surfaceElevated]. Three values apart is enough to read as
  // raised, which is exactly why the surfaces are spaced that far apart.
  //
  // The one place light *is* used to build depth is glass: a frosted panel gets
  // a lit top edge instead of a shadow underneath, which is depth by what the
  // surface reflects rather than by what it blocks. See `GlassRim`.
}
