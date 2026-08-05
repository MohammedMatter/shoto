/// What a completed backup produced.
class BackupResult {
  /// Where the archive was written on this device.
  final String filePath;
  final int screenshots;
  final int folders;
  final int bytes;

  /// Screenshots in the library whose image could not be read off the device.
  ///
  /// Always reported, never hidden. A backup that quietly leaves things out is
  /// worse than one that fails, because the user believes they are covered.
  final int unreadable;

  const BackupResult({
    required this.filePath,
    required this.screenshots,
    required this.folders,
    required this.bytes,
    required this.unreadable,
  });

  bool get isComplete => unreadable == 0;
}

/// What a completed restore put back.
class RestoreResult {
  final int screenshots;
  final int folders;

  /// Entries the archive listed but could not supply — a truncated file, or
  /// one written by a build that knew fields this one does not.
  final int missing;

  /// Images that came out of the archive but the device refused to save.
  final int failed;

  const RestoreResult({
    required this.screenshots,
    required this.folders,
    required this.missing,
    required this.failed,
  });

  bool get isComplete => missing == 0 && failed == 0;
}
