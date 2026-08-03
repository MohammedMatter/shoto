import 'package:shoto/core/localization/app_message.dart';
import 'dart:typed_data';

/// A finished long screenshot, still in memory — nothing is written to the
/// gallery until the user has seen it and said yes.
class StitchOutcome {
  final Uint8List pngBytes;
  final int width;
  final int height;

  /// How many captures went into it.
  final int sourceCount;

  /// Total pixels of duplicated content that were removed at the joins.
  /// Shown to the user as proof the merge actually did something.
  final int trimmedRows;

  const StitchOutcome({
    required this.pngBytes,
    required this.width,
    required this.height,
    required this.sourceCount,
    required this.trimmedRows,
  });
}

/// A stitch that couldn't be completed, carrying a reason worth showing the
/// user rather than a generic failure.
///
/// The distinction matters: "these two don't overlap" is something they can
/// fix by picking different screenshots, while "the images are different
/// widths" tells them the captures came from different screens.
/// Carries an [AppMessage] rather than a sentence.
///
/// The stitcher fails in seven genuinely different ways and each one tells the
/// user something different about what to do next — "these are different
/// widths" and "these do not overlap" are not the same advice. Keeping them
/// distinct *and* translated means the thing thrown has to name a message
/// instead of being one, because nothing down here has a BuildContext.
class StitchException implements Exception {
  final AppMessage message;

  const StitchException(this.message);

  @override
  String toString() => 'StitchException($message)';
}
