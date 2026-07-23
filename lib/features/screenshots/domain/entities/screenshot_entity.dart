import 'package:photo_manager/photo_manager.dart';

class ScreenshotEntity {
  final AssetEntity asset;
  final bool isFavorite;
  final int? folderId;

  const ScreenshotEntity({
    required this.asset,
    required this.isFavorite,
    required this.folderId,
  });

  String get id => asset.id;

  ScreenshotEntity copyWith({
    bool? isFavorite,
    int? folderId,
    bool clearFolder = false,
  }) {
    return ScreenshotEntity(
      asset: asset,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
    );
  }
}
