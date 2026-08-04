import 'package:shoto/features/backup/domain/entities/backup_outcome.dart';
import 'package:shoto/features/backup/domain/repositories/backup_repository.dart';

class RestoreBackupUseCase {
  final BackupRepository repository;
  RestoreBackupUseCase(this.repository);

  Future<RestoreResult> call(
    String filePath, {
    void Function(int done, int total)? onProgress,
  }) => repository.restoreBackup(filePath, onProgress: onProgress);
}
