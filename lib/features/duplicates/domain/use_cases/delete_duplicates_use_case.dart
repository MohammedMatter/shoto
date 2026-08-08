import 'package:shoto/features/duplicates/domain/repositories/duplicates_repository.dart';

class DeleteDuplicatesUseCase {
  final DuplicatesRepository repository;
  DeleteDuplicatesUseCase(this.repository);

  /// Returns the ids actually deleted, which the caller must report rather
  /// than the ids it asked for.
  Future<List<String>> call(List<String> assetIds) =>
      repository.deleteScreenshots(assetIds);
}
