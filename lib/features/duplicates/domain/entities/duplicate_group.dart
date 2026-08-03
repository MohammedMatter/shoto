import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

/// One screenshot inside a duplicate group, paired with its on-disk size so
/// the review screen can show how much space deleting it would reclaim.
class DuplicateCandidate {
  final ScreenshotEntity screenshot;
  final int fileSizeBytes;

  const DuplicateCandidate({
    required this.screenshot,
    required this.fileSizeBytes,
  });

  String get id => screenshot.id;
}

/// A set of screenshots that look the same to the eye.
///
/// [suggestedKeeperId] is only a *suggestion* — the review screen pre-selects
/// everything else for deletion but the user stays in control of the final
/// choice, because a wrong guess here permanently destroys someone's photo.
class DuplicateGroup {
  final List<DuplicateCandidate> candidates;
  final String suggestedKeeperId;

  const DuplicateGroup({
    required this.candidates,
    required this.suggestedKeeperId,
  });

  /// Stable identity for this group across rebuilds — the keeper's asset id
  /// is unique and doesn't change while the group exists.
  String get id => suggestedKeeperId;

  int get duplicateCount => candidates.length - 1;

  /// Bytes freed if every candidate except the keeper is deleted.
  int get reclaimableBytes => candidates
      .where((candidate) => candidate.id != suggestedKeeperId)
      .fold(0, (sum, candidate) => sum + candidate.fileSizeBytes);
}
