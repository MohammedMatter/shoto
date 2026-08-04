import 'package:shoto/features/backup/domain/entities/restore_plan.dart';
import 'package:shoto/features/backup/domain/repositories/backup_repository.dart';

class PreviewBackupUseCase {
  final BackupRepository repository;
  PreviewBackupUseCase(this.repository);

  Future<BackupPreview> call(String filePath) =>
      repository.previewBackup(filePath);
}
