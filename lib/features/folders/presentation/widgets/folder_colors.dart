/// Colours a user can tag a folder with.
///
/// These are the one place in SHOTO where saturated colour is still correct:
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
const List<int> kFolderColors = [
  0xFF5B8DEF, // blue — replaces the clay
  0xFF33E0C2, // teal
  0xFFFF8A65, // coral
  0xFFFFC857, // amber
  0xFF7E9B5E, // sage — replaces the light blue
  0xFFEF5DA8, // pink
];
