/// Which slice of the library the grid is showing.
///
/// This was a single `favoritesOnly` boolean, and a boolean can only ever
/// describe two slices — neither of which was the one the whole app is built
/// around. Home's hero counts the screenshots that have been *neither filed
/// nor starred*, and tapping it opened the Library on everything: the number
/// said 7, the grid handed back 8, and there was no way to see which 7 it had
/// meant. The count was an answer to a question the next screen could not
/// repeat.
///
/// Three named slices rather than two booleans, because two booleans would
/// allow `unsorted && favorites`, which is a contradiction — nothing starred
/// is unsorted. An enum makes that state unrepresentable instead of merely
/// unlikely.
enum LibraryFilter { all, unsorted, favorites }
