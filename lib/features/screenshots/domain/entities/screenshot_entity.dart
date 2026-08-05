import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';

class ScreenshotEntity {
  final AssetEntity asset;
  final bool isFavorite;
  final int? folderId;

  /// What the user said they would do with this, and whether they have.
  ///
  /// Null for the great majority: an intent is a deliberate one-tap answer,
  /// not something every screenshot acquires by existing.
  final IntentState? intent;

  const ScreenshotEntity({
    required this.asset,
    required this.isFavorite,
    required this.folderId,
    this.intent,
  });

  /// An intent the user has set and not yet ticked off.
  ///
  /// The app's only shrinking number is built on this, so it is defined once
  /// here for the same reason [isUnsorted] is — Home, the intent screens and
  /// the counts all have to agree, and two hand-written copies of the
  /// condition is how they stop agreeing.
  bool get isWaiting => intent?.isWaiting ?? false;

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
    IntentState? intent,
    bool clearIntent = false,
  }) {
    return ScreenshotEntity(
      asset: asset,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      intent: clearIntent ? null : (intent ?? this.intent),
    );
  }
}
