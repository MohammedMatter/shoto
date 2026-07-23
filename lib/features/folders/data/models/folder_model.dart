import 'package:shoto/features/folders/domain/entities/folder_entity.dart';

class FolderModel extends FolderEntity {
  const FolderModel({
    required super.id,
    required super.name,
    required super.color,
    required super.createdAt,
    super.screenshotCount,
  });

  factory FolderModel.fromMap(
    Map<String, Object?> map, {
    int screenshotCount = 0,
  }) {
    return FolderModel(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      screenshotCount: screenshotCount,
    );
  }
}
