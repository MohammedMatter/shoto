import 'package:shoto/core/utils/screenshot_intent.dart';

/// Everything Home needs to draw its first screen, answerable **without
/// touching the gallery**.
///
/// ## Why this exists
///
/// A library read is `MediaStore` first and the database second: enumerate the
/// album, then intersect it with the rows saying which of those images are
/// actually in Shoto, then join the organization onto that. The first of those
/// three is by far the slowest thing the app does, and on a cold start it also
/// pays for the plugin channel waking up — so the whole page waited on the
/// gallery before a single number could be drawn.
///
/// But the two numbers Home leads with — how much is unsorted, and what is
/// waiting under each verb — are not facts about the gallery at all. They are
/// facts about `library_assets` and `screenshot_meta`, which are two local
/// tables that answer in a millisecond. The gallery is needed only for the
/// *pictures*.
///
/// So the read is split. This is the half that can be had immediately, and Home
/// draws its real inbox from it while the pictures are still coming.
///
/// ## What it is not
///
/// **Not a cache.** Nothing writes this; it is computed from the same rows the
/// real read joins against, every time it is asked. There is no snapshot to go
/// stale, no invalidation to get wrong, and no state where the number shown is
/// from a previous session.
///
/// It can still be a slight *over*-count for one reason: an image deleted from
/// the phone outside Shoto still has its rows here until the next real read
/// notices the asset is gone. That is a picture the user themselves removed
/// somewhere else, the number is corrected a moment later by the read already
/// in flight, and the alternative — showing nothing — is the bug this was
/// written to fix.
class LibrarySummary {
  /// How many screenshots this device's library claims.
  final int total;

  /// Never filed, never starred. Mirrors `ScreenshotEntity.isUnsorted`.
  final int unsorted;

  /// Still-waiting counts per verb, in [IntentRef.pickerOrder] — the same order
  /// `ScreenshotsLoadedState.waitingByIntent` uses, so the tags do not
  /// rearrange when the real read replaces this one.
  final Map<IntentRef, int> waiting;

  const LibrarySummary({
    required this.total,
    required this.unsorted,
    required this.waiting,
  });

  /// A library with nothing in it — also what a failed read degrades to, since
  /// a summary is an optimisation and must never be the reason a screen breaks.
  static const LibrarySummary empty = LibrarySummary(
    total: 0,
    unsorted: 0,
    waiting: <IntentRef, int>{},
  );

  /// Nothing to draw from. Home falls back to neutral placeholders rather than
  /// claiming a library state it cannot support.
  bool get isEmpty => total == 0;
}
