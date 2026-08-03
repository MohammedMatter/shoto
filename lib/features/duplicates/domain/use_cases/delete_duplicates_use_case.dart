import 'package:shoto/features/duplicates/domain/repositories/duplicates_repository.dart';

class DeleteDuplicatesUseCase {
  final DuplicatesRepository repository;
  DeleteDuplicatesUseCase(this.repository);

  Future<void> call(List<String> assetIds) =>
      repository.deleteScreenshots(assetIds);
}
