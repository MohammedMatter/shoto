/// Which end of the library the grid starts from.
///
/// Deliberately only two values. Sorting by name would sort by the filename
/// the phone's screenshot tool invented, which nobody chose and nobody
/// recognises; sorting by size would need every asset's byte count read off
/// disk before the first tile could be drawn. Both would be options that look
/// like features in a menu and answer no question anybody has.
///
/// Separate from `LibraryFilter` and the trait lens because it is a third
/// independent axis: which slice, which contents, and which order are three
/// questions, and folding any two together makes combinations unreachable.
enum LibrarySort {
  /// Newest first. The default, and right for a library whose whole premise
  /// is that the thing you just captured is the thing you want.
  newest,

  /// Oldest first — for finding the screenshot you took months ago and have
  /// been scrolling past ever since.
  oldest;

  bool get isNewestFirst => this == LibrarySort.newest;
}
