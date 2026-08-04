import 'package:shoto/features/backup/domain/entities/backup_outcome.dart';
import 'package:shoto/features/backup/domain/repositories/backup_repository.dart';

class CreateBackupUseCase {
  final BackupRepository repository;
  CreateBackupUseCase(this.repository);

  Future<BackupResult> call({void Function(int done, int total)? onProgress}) =>
      repository.createBackup(onProgress: onProgress);
}
