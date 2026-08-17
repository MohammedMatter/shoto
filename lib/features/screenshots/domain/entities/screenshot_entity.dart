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

  /// When the user asked to be brought back to this, if they did.
  ///
  /// Kept beside [intent] rather than inside it because they are cleared by
  /// different events: an intent ends when the user says they did the thing, a
  /// reminder is spent the moment it fires. A screenshot can also carry one
  /// without the other — a reminder with no verb is "look at this again", and
  /// most verbs never need an alarm.
  final DateTime? remindAt;

  const ScreenshotEntity({
    required this.asset,
    required this.isFavorite,
    required this.folderId,
    this.intent,
    this.remindAt,
  });

  /// A reminder that has been set and has not yet come round.
  ///
  /// Defined here for the same reason as [isWaiting]: the detail page, the
  /// picker sheet and anything that lists pending reminders all have to agree
  /// about what "still coming" means, and `remindAt!.isAfter(DateTime.now())`
  /// written three times is how they stop agreeing.
  bool get hasPendingReminder =>
      remindAt != null && remindAt!.isAfter(DateTime.now());

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
    DateTime? remindAt,
    bool clearReminder = false,
  }) {
    return ScreenshotEntity(
      asset: asset,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      intent: clearIntent ? null : (intent ?? this.intent),
      remindAt: clearReminder ? null : (remindAt ?? this.remindAt),
    );
  }
}
