import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';
import 'package:shoto/features/duplicates/domain/repositories/duplicates_repository.dart';

class FindDuplicatesUseCase {
  final DuplicatesRepository repository;
  FindDuplicatesUseCase(this.repository);

  Future<List<DuplicateGroup>> call({
    void Function(int processed, int total)? onProgress,
  }) => repository.findDuplicates(onProgress: onProgress);
}
