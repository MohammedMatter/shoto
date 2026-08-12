import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

/// Puts something in the Folders tab before the user has ever opened it.
///
/// **The empty state was the problem this solves.** Filing is the one habit
/// this whole app is asking for, and the screen that asks for it opened on a
/// grey glyph, a sentence and a button — a form to fill in before anything
/// could happen. Seven folders that are already there turn that into a much
/// smaller question: not "invent a filing system", but "which of these do I
/// use". The ones nobody uses are two taps to delete.
///
/// Returns whether anything was actually written; see the repository for why
/// this can only ever fire once.
class SeedDefaultFoldersUseCase {
  final FoldersRepository repository;
  SeedDefaultFoldersUseCase(this.repository);

  Future<bool> call(List<FolderSeed> seeds) =>
      repository.seedDefaultFolders(seeds);
}
