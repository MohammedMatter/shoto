import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

/// Replaces `RenameFolderUseCase`.
///
/// A folder now has three editable things about it — its name, its colour and
/// its glyph — and they are all chosen on one sheet, in one sitting. A use case
/// that could only carry the name would have meant the other two travelling by
/// some second route, which is how a folder ends up renamed but still wearing
/// the wrong picture.
class UpdateFolderUseCase {
  final FoldersRepository repository;
  UpdateFolderUseCase(this.repository);

  Future<void> call(
    int folderId, {
    required String name,
    required int color,
    String? iconKey,
  }) => repository.updateFolder(
    folderId,
    name: name,
    color: color,
    iconKey: iconKey,
  );
}
