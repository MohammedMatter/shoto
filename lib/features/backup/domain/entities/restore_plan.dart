/// What a backup file holds, read without restoring any of it.
///
/// Exists so the app can ask its one question *before* doing the work: which
/// folders in the file already exist here, and what should happen to them.
/// Asking afterwards would mean asking about duplicates that already exist.
class BackupPreview {
  final List<String> folderNames;
  final int screenshots;

  /// Names in the file that the current library already uses.
  final List<String> collidingFolderNames;

  const BackupPreview({
    required this.folderNames,
    required this.screenshots,
    required this.collidingFolderNames,
  });

  bool get hasCollisions => collidingFolderNames.isNotEmpty;
}

/// What to do with a folder in the backup whose name is already taken.
enum FolderMergeChoice {
  /// File its screenshots into the folder that is already here.
  merge,

  /// Make a second folder with the same name.
  ///
  /// Not the default, but not wrong either: two people can genuinely have two
  /// different folders called "Work", and silently pouring one into the other
  /// is the mistake nobody notices until the wrong screenshots are together.
  keepSeparate,
}
