import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';

class FoldersEvent {}

class LoadFoldersEvent extends FoldersEvent {}

class CreateFolderEvent extends FoldersEvent {
  final String name;
  final int color;
  final bool isPrivate;
  final String? iconKey;
  CreateFolderEvent(
    this.name,
    this.color, {
    this.isPrivate = false,
    this.iconKey,
  });
}

/// Replaces `RenameFolderEvent`: the sheet that edits a folder shows its name,
/// its colour and its glyph, so it hands all three back at once.
class UpdateFolderEvent extends FoldersEvent {
  final int folderId;
  final String name;
  final int color;
  final String? iconKey;
  UpdateFolderEvent(
    this.folderId, {
    required this.name,
    required this.color,
    this.iconKey,
  });
}

class DeleteFolderEvent extends FoldersEvent {
  final int folderId;
  DeleteFolderEvent(this.folderId);
}

class SetFolderSortEvent extends FoldersEvent {
  final FolderSort sort;
  SetFolderSortEvent(this.sort);
}

/// Offers the starter folders, carrying names already resolved into the
/// device's language — see [FolderSeed] for why translation happens up here
/// and not in the data layer.
class SeedDefaultFoldersEvent extends FoldersEvent {
  final List<FolderSeed> seeds;
  SeedDefaultFoldersEvent(this.seeds);
}
