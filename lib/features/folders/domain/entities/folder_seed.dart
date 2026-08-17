/// One folder Shoto offers to make for you, before you have made any.
///
/// **A name, and nothing that knows how to translate itself.** The names are
/// resolved from `.arb` files at the call site, in the presentation layer,
/// which is the only place that has a `BuildContext` to ask — and the only
/// place that should. What lands in the database afterwards is a plain string:
/// a folder called "Rezepte" on a German phone is the user's folder from that
/// moment on, and switching the phone to English later must not silently
/// rewrite it. That is the same rule a custom intent follows ("the user's own
/// words, in the language they typed them"), applied one step earlier — to
/// words Shoto typed on their behalf.
class FolderSeed {
  final String name;
  final int color;
  final String iconKey;

  const FolderSeed({
    required this.name,
    required this.color,
    required this.iconKey,
  });
}
