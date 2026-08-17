import 'dart:ui';

import 'package:shoto/core/utils/sensitive_data.dart';

/// What Shoto will do about one private detail.
///
/// Two states, and the shorter list is the point. There used to be a third —
/// redrawing the area with an invented but believable value, so the copy did
/// not look edited at all. It was clever and it was the wrong promise: it
/// asked the user to trust that the app had put the right lie in the right
/// place, on a screen whose entire job is to be trusted. A solid block makes
/// one claim and it is checkable at a glance.
enum RegionTreatment {
  /// Paint a solid block over it. Nothing to reconstruct, nothing to reverse.
  cover,

  /// Leave it exactly as it is, because the app was wrong about it.
  keep,
}

/// One private detail found in a screenshot, and where it sits.
///
/// The rectangle is in the *source image's* pixel space, not the screen's.
/// Keeping it that way means the same region can be drawn on a preview at any
/// size and burned into the exported file at full resolution without a second
/// conversion — and a coordinate space converted twice is a coordinate space
/// that ends up half a box off.
class SensitiveRegion {
  final SensitiveKind kind;

  /// The area that will be covered. Wider than the private value itself when
  /// the value shares a word with something else — see `TextLineGeometry`.
  final Rect bounds;

  /// Identifies the run of text [bounds] belongs to.
  ///
  /// Two details found in the same run — a name and the phone number printed
  /// against it, when OCR read them as one word — are two entries in the
  /// review list but a single piece of the image, and it is painted once.
  final String runId;

  /// The run's text as it appears in the screenshot, and where this detail
  /// sits inside it.
  final String runText;
  final int localStart;
  final int localEnd;

  /// What is really there.
  final String original;

  /// Whether the run reads right to left. Kept because the geometry helpers
  /// and the preview both need to know.
  final bool isRtl;

  final RegionTreatment treatment;

  const SensitiveRegion({
    required this.kind,
    required this.bounds,
    required this.runId,
    required this.runText,
    required this.localStart,
    required this.localEnd,
    required this.original,
    required this.isRtl,
    this.treatment = RegionTreatment.cover,
  });

  SensitiveRegion copyWith({RegionTreatment? treatment}) => SensitiveRegion(
    kind: kind,
    bounds: bounds,
    runId: runId,
    runText: runText,
    localStart: localStart,
    localEnd: localEnd,
    original: original,
    isRtl: isRtl,
    treatment: treatment ?? this.treatment,
  );

  /// The real value, shortened for the review list.
  ///
  /// Numbers are shown by their last four characters only. The point of this
  /// screen is to get a card number out of a picture; printing it back in
  /// full underneath, in a list, would be absurd — and the last four is
  /// exactly how every bank already refers to a card, so it identifies the
  /// line without repeating the secret.
  String get maskedOriginal {
    final String clean = original.replaceAll(RegExp(r'\s+'), ' ').trim();
    switch (kind) {
      case SensitiveKind.card:
      case SensitiveKind.iban:
      case SensitiveKind.nationalId:
      case SensitiveKind.code:
      case SensitiveKind.number:
        if (clean.length <= 4) return clean;
        return '•••• ${clean.substring(clean.length - 4)}';
      case SensitiveKind.personName:
      case SensitiveKind.postalAddress:
      case SensitiveKind.phone:
      case SensitiveKind.email:
      case SensitiveKind.orderNumber:
        return clean.length <= 30 ? clean : '${clean.substring(0, 29)}…';
    }
  }
}

/// Everything found in one screenshot, plus the size of the image the
/// rectangles refer to.
class RedactionPlan {
  final List<SensitiveRegion> regions;
  final Size imageSize;

  const RedactionPlan({required this.regions, required this.imageSize});

  bool get isEmpty => regions.isEmpty;

  /// How many details will actually be covered — the number the share button
  /// counts, and never the number found.
  int get handledCount => regions
      .where((SensitiveRegion r) => r.treatment != RegionTreatment.keep)
      .length;

  /// The kinds found, most damaging first, each with how many there are.
  ///
  /// This is what the free scan reports: "4 private details — your location,
  /// your account number, your name, your phone number". A list of kinds says
  /// something a count cannot.
  Map<SensitiveKind, int> get countsByKind {
    final Map<SensitiveKind, int> counts = <SensitiveKind, int>{};
    for (final SensitiveRegion region in regions) {
      counts[region.kind] = (counts[region.kind] ?? 0) + 1;
    }
    final List<SensitiveKind> ordered = counts.keys.toList()
      ..sort((SensitiveKind a, SensitiveKind b) => a.index.compareTo(b.index));
    return <SensitiveKind, int>{
      for (final SensitiveKind kind in ordered) kind: counts[kind]!,
    };
  }

  RedactionPlan withRegions(List<SensitiveRegion> updated) =>
      RedactionPlan(regions: updated, imageSize: imageSize);
}
