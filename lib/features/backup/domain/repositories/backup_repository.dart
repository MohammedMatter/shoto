import 'package:shoto/features/backup/domain/entities/backup_outcome.dart';
import 'package:shoto/features/backup/domain/entities/restore_plan.dart';

/// Writing the signed-in account's library to a file, and putting one back.
///
/// Everything here is scoped to the current account, same as every other
/// repository in the app: a backup holds one person's library, and restoring
/// puts it into whoever is signed in at the time.
abstract class BackupRepository {
  /// Builds an archive of the whole library and returns where it was written.
  ///
  /// [onProgress] fires as each screenshot is read, so a library of several
  /// hundred can show movement rather than a spinner that looks stuck.
  Future<BackupResult> createBackup({
    void Function(int done, int total)? onProgress,
  });

  /// Reads the file's index only, so the app can ask about folder-name
  /// collisions before anything is written.
  Future<BackupPreview> previewBackup(String filePath);

  /// Reads [filePath] and adds everything in it to the current library.
  ///
  /// **Adds — it never replaces.** Restoring onto a phone that already has
  /// screenshots leaves them alone; the alternative is a feature whose worst
  /// case is destroying the library it was opened to protect.
  Future<RestoreResult> restoreBackup(
    String filePath, {
    FolderMergeChoice onNameClash = FolderMergeChoice.keepSeparate,
    void Function(int done, int total)? onProgress,
  });
}
