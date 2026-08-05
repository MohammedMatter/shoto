/// What version one actually ships.
///
/// **Two features were built for an app that no longer exists.** Find
/// duplicates and Stitch were written when SHOTO read the whole device
/// gallery, and both of them answer questions that only a gallery-scale
/// library asks:
///
/// * You do not accumulate duplicates in a set you assembled by hand, one
///   deliberate share at a time. Scanning it finds nothing, and a paid
///   feature whose honest answer is "nothing found" is worse than no feature.
/// * Stitch needs you to take two to five overlapping long-scroll captures,
///   share every one of them into SHOTO, then find and multi-select them. The
///   capture cost is higher than the thing it saves you, and the phones most
///   likely to be used for it have scrolling capture built into the shutter.
///
/// Neither was re-examined when the premise reversed. They are off rather
/// than deleted because the code is good, tested, and cheap to keep — the
/// argument here is about what a first release should *contain*, and that
/// argument can be lost. Flipping either constant back restores the feature
/// whole. See `docs/decisions/v1-scope.md`.
abstract class V1Features {
  V1Features._();

  /// The duplicate finder: dHash, union-find clustering, the review screen.
  static const bool duplicates = false;

  /// Merging overlapping long-scroll captures into one tall image.
  static const bool stitch = false;
}
