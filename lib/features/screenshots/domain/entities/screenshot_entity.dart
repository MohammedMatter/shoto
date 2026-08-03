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

  /// Still waiting on the user: never filed into a folder, never starred.
  ///
  /// Defined once, here, because it is the app's central number — Home sets
  /// its hero from it and the Library filters by it, and two hand-written
  /// copies of `folderId == null && !isFavorite` are exactly how a screen ends
  /// up promising a count the next screen cannot reproduce.
  bool get isUnsorted => folderId == null && !isFavorite;

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
