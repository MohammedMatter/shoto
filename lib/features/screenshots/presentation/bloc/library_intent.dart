/// A job the user started **somewhere else** and has to pick screenshots for.
///
/// Home advertises every capability the app has, including two that need
/// pictures it does not have: safe share works on one screenshot, merging on
/// two or more. So both rows used to answer a tap with a sentence —
///
/// > "Long-press two or more screenshots in your library, then tap Merge."
///
/// — which is a button that turns out to be a sign-post. The user is told the
/// steps and left to walk them, on a screen they have to find first, using a
/// gesture with no visual affordance. An app that knows exactly what needs to
/// happen next should do it rather than describe it.
///
/// Carrying the intent into the Library lets the tap *start* the job: the tab
/// changes, selection mode is already on, and a line at the top says what to
/// pick. The user's only remaining job is the one thing the app genuinely
/// cannot do for them, which is choosing which screenshots.
///
/// [none] is the ordinary case — selection the user began themselves by
/// long-pressing a tile, where nothing needs explaining.
enum LibraryIntent {
  none,

  /// Merging. Needs two or more.
  merge,

  /// Safe share. Needs exactly one.
  protect;

  /// Whether this intent was set by another screen, and therefore whether the
  /// Library owes the user a prompt.
  bool get isGuided => this != LibraryIntent.none;
}
