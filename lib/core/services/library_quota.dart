import 'package:flutter/foundation.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_managed_screenshot_count_use_case.dart';

/// How much of the free tier's one allowance has been spent, as a value the
/// app can paint.
///
/// The number itself was always available — [GetManagedScreenshotCountUseCase]
/// has existed as long as the cap has — but only as a `Future`, and only ever
/// awaited at the moment of the block. That is the right shape for a gate and
/// the wrong shape for a screen: painting cannot await, so nothing could ever
/// *show* somebody where they stood. The result was a limit a user met exactly
/// once, head-on, as a paywall — with no warning that it was coming and no way
/// to look it up afterwards.
///
/// Modelled on [ProStatus] deliberately, down to the nullable field: "not
/// counted yet" and "nothing kept" are different answers, and a meter that
/// renders at zero for a frame before jumping to 87 is a worse lie than a
/// meter that renders nothing. Settings already listens to [ProStatus]; this
/// joins that same `Listenable.merge` and costs the page nothing extra.
///
/// **This is not a gate**, for the same reason [ProStatus] is not one:
/// `ensureUnderScreenshotLimit` still counts for itself at the moment of the
/// action. A cached number is fine for drawing a bar and not fine for deciding
/// whether somebody may keep another screenshot.
class LibraryQuota extends ChangeNotifier {
  final GetManagedScreenshotCountUseCase _managedCount;
  final ProStatus _pro;

  LibraryQuota(this._managedCount, this._pro);

  int? _used;

  /// Screenshots this device has brought under management — favorited, or
  /// filed into a folder. Null until the first count lands.
  int? get used => _used;

  /// The ceiling, or null when there is not one.
  ///
  /// Null rather than a very large number: "unlimited" is a different kind of
  /// answer from "a big allowance", and a meter drawn at 87/999999 is a bar
  /// that is always empty rather than a bar that does not apply.
  int? get limit =>
      _pro.isPro ? null : SubscriptionConstants.freeScreenshotLimit;

  bool get isUnlimited => limit == null;

  /// How full the allowance is, from 0 to 1, or null when there is no ceiling
  /// or no count yet.
  ///
  /// Clamped at the top because the cap can be crossed legitimately: the gate
  /// only ever refuses *new* items, so somebody who was over the line before
  /// the limit existed — or who subscribed, filled up and lapsed — keeps every
  /// screenshot they already had. A bar that overflows its own track is a
  /// rendering bug; the honest way to say "past the line" is the number beside
  /// it, which is never clamped.
  double? get fraction {
    final int? cap = limit;
    final int? spent = _used;
    if (cap == null || spent == null || cap <= 0) return null;
    return (spent / cap).clamp(0.0, 1.0);
  }

  /// True once the allowance is spent. False while the count is unknown —
  /// never warn on a maybe.
  bool get isFull {
    final int? cap = limit;
    final int? spent = _used;
    return cap != null && spent != null && spent >= cap;
  }

  /// Starts tracking. Called once from `main`, after [ProStatus.load], so the
  /// first visit to Settings already has a number rather than fading one in.
  Future<void> load() async {
    // Paying removes the ceiling, which changes what this reports without the
    // count itself moving. Listening means the meter turns into "Unlimited" in
    // the same frame the purchase lands, rather than the next time somebody
    // happens to open the Settings tab.
    _pro.addListener(notifyListeners);
    await refresh();
  }

  /// Re-counts. Cheap — one `COUNT(*)` against the local metadata table — so
  /// the shell can call it on every visit to the Settings tab rather than
  /// trying to be clever about when the library might have changed.
  Future<void> refresh() async {
    try {
      final int next = await _managedCount();
      if (next == _used) return;
      _used = next;
      notifyListeners();
    } catch (_) {
      // A failed count must not wipe a good one. The meter going blank because
      // a query lost a race would read as "you have nothing", which is the
      // most alarming thing this widget could possibly say by accident.
    }
  }

  @override
  void dispose() {
    _pro.removeListener(notifyListeners);
    super.dispose();
  }
}
