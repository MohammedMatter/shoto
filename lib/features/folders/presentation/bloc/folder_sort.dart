/// Which order the folder grid is shown in.
///
/// **Three values, where the library's own sort deliberately has two.**
/// `LibrarySort` argues against sorting by name because the name would be the
/// filename the phone's screenshot tool invented — nobody chose it and nobody
/// recognises it. That argument does not reach here and in fact inverts: a
/// folder's name is the one thing about it the user typed themselves, and
/// alphabetical is how somebody with twenty folders finds "Recipes" without
/// reading twenty tiles.
///
/// [fullest] is the third question a grid of folders provokes and neither of
/// the others answers: which of these am I actually using.
enum FolderSort {
  /// Newest first. The default, and what the table was already ordered by —
  /// the folder you just made is the one you are about to file into.
  recent,

  /// A to Z, by the user's own words.
  name,

  /// Most screenshots first.
  fullest,
}
