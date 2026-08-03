import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';
import 'package:shoto/features/stitch/domain/repositories/stitch_repository.dart';

class SaveStitchedImageUseCase {
  final StitchRepository repository;
  SaveStitchedImageUseCase(this.repository);

  Future<String> call(StitchOutcome outcome) => repository.save(outcome);
}
