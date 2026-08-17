import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_colors.dart';

/// Colours a user can tag a folder with.
///
/// These are the one place in Shoto where saturated colour is still correct:
/// they are labels the user chooses, and telling six folders apart at a
/// glance is exactly what colour is good at. They are not the interface
/// speaking, they are the user's own filing marks.
///
/// The set has been edited twice. First a violet and a light blue came out,
/// because they put the app's retired blue-violet accent back on screen every
/// time a folder was created; they were replaced with a clay and a sage that
/// matched the warm neutrals the app ran on at the time.
///
/// Then the clay came out too. The neutrals are achromatic now, and a
/// copper-brown label was the single most saturated piece of exactly the cast
/// this palette was rebuilt to remove — a folder tagged with it tinted the
/// card, the shadow and the header of its own screen. A blue replaces it, and
/// blue is safe again for the same reason clay stopped being: there is no
/// longer an accent hue for it to be confused with.
///
/// **Existing folders keep the colour they were saved with.** The value is
/// stored as an int per folder in the database, so a folder already tagged
/// violet stays violet until somebody re-picks it — this list only governs
/// what is offered from now on.
/// **Violet is back, and orange is new.**
///
/// The violet came out, three revisions ago, because it "put the app's retired
/// blue-violet accent back on screen every time a folder was created". That
/// reason expired with the accent: `AppPalette.marker` is a slate blue at 43%
/// saturation now, and it is the same argument that let the blue back in one
/// line above — there is no longer an accent hue for either of them to be
/// confused with. A grid of folders that cannot offer a purple is a grid
/// missing the colour people reach for second.
const List<int> kFolderColors = [
  0xFF5B8DEF, // blue — replaces the clay
  0xFF8B7BF0, // violet — readmitted, see above
  0xFF33E0C2, // teal
  0xFF7E9B5E, // sage — replaces the light blue
  0xFFFFC857, // amber
  0xFFF5883C, // orange
  0xFFFF8A65, // coral
  0xFFEF5DA8, // pink
];

/// A foreground that stays legible on any of the above — and on any colour a
/// folder was saved with before the list was last edited.
///
/// The swatch picker drew a hard-coded white tick on all six. It is invisible
/// on the amber and barely there on the teal, which are by some distance the
/// two lightest, so the confirmation that a colour had been chosen disappeared
/// on exactly the colours somebody is most likely to choose.
///
/// Deliberately **not** an [AppPalette] value. These are the user's own filing
/// marks, they do not follow the theme, and picking a foreground for them is a
/// question about the swatch rather than about the interface. Threshold 0.45
/// rather than the usual 0.5 because the tick is a thin glyph — it needs a
/// little more room than a solid block would.
Color onFolderColor(int value) =>
    Color(value).computeLuminance() > 0.45 ? AppPalette.ink : AppPalette.paper;

/// The back of the folder — the card stock, behind the pocket.
///
/// Derived from the saved colour rather than stored as a second value, which
/// is the only version of this that can work: every folder already in every
/// database has exactly one int in it, and a folder tagged with a colour that
/// left [kFolderColors] two revisions ago still has to come out looking like a
/// folder.
///
/// Two moves, both downward. Lightness drops to 78% of the tag's own, which is
/// what makes the pocket in front read as lit rather than as a second panel of
/// the same colour; saturation drops with it, because a colour held at full
/// chroma while it darkens goes muddy rather than deep — the same finding the
/// palette recorded when it tried to push amber down to the family luminance
/// and got brown.
///
/// **78% and not 58%.** The first attempt took a fifth more out of the
/// lightness and it was visibly wrong on the warm end of the set: coral came
/// out as a dark red and orange as a brown, so two of the eight swatches
/// stopped being the colour the user had picked by the time they reached the
/// biggest area of the card. The plate has to be *the same colour, in shadow* —
/// far enough down to sit behind the pocket, not so far that it changes name.
Color folderPlateColor(int value) {
  final HSLColor base = HSLColor.fromColor(Color(value));
  return base
      .withLightness((base.lightness * 0.78).clamp(0.0, 1.0))
      .withSaturation((base.saturation * 0.80).clamp(0.0, 1.0))
      .toColor();
}

/// The pocket on the front, where the folder's name is written.
///
/// **Symmetric around the saved colour on purpose**: ten points of lightness
/// up at the top-start corner, ten down at the bottom-end one, so the midpoint
/// of the sweep *is* the tag the user picked. That is not tidiness — it is
/// what keeps [onFolderColor] correct. A foreground chosen against the base
/// colour is the right foreground for a gradient whose average is that colour,
/// and it means the amber folder still gets ink on it without a second
/// luminance test per stop.
///
/// This is the one gradient in the app, and it is allowed for the reason this
/// file has always given for the colours themselves: it is the user's own
/// filing mark, not the interface speaking. `AppPalette` flattened its
/// twenty-two gradients because they were *chrome* — a sweep across a button
/// says nothing about the button.
LinearGradient folderPocketGradient(int value) {
  final HSLColor base = HSLColor.fromColor(Color(value));
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      base.withLightness((base.lightness + 0.10).clamp(0.0, 1.0)).toColor(),
      base.withLightness((base.lightness - 0.10).clamp(0.0, 1.0)).toColor(),
    ],
  );
}
