import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// Whether this account is on Pro, as one value the whole app can watch.
///
/// Every screen that wants to know used to ask for itself, and each one
/// answered the question differently:
///
/// * The settings card called [SubscriptionRepository.getStatus] in
///   `initState` and cached the reply in a **static field** so that scrolling
///   it out of the list and back did not fire a platform-channel round trip
///   mid-drag. That static was the app's real source of truth, owned by a
///   widget, reachable by nothing else.
/// * `ensurePremium` awaits a fresh call on every tap, which is right for a
///   gate — it must never let someone through on stale state — and useless for
///   anything that has to *paint* a badge, because painting cannot await.
/// * Nothing at all could show Pro anywhere else, since there was no
///   synchronous answer to read during a build.
///
/// So the answer lives here instead: resolved once, kept current, and read
/// synchronously by anyone painting. It is a [ChangeNotifier], so a badge on
/// Home and a card in Settings light up in the same frame the purchase lands
/// — without either of them knowing the other exists.
///
/// **This is not a gate.** [ensurePremium] deliberately still asks the
/// repository directly. A cached "yes" is fine for deciding whether to draw a
/// badge and not fine for deciding whether to open a paid feature, and keeping
/// those two questions on separate paths is what stops a stale cache from ever
/// becoming a way in.
class ProStatus extends ChangeNotifier {
  final SubscriptionRepository _repository;
  final DevAccess _devAccess;

  StreamSubscription<SubscriptionStatus>? _changes;

  ProStatus(this._repository, this._devAccess);

  SubscriptionStatus? _status;

  /// Null until the first answer arrives.
  ///
  /// Kept nullable rather than defaulting to [SubscriptionStatus.free],
  /// because "not known yet" and "not subscribed" are different things and the
  /// settings card already learned that the hard way: rendering the upsell
  /// while the real answer was still in flight put an advertisement on a
  /// paying customer's own settings screen, and made the card change height
  /// under their thumb when the truth landed.
  SubscriptionStatus? get status => _status;

  /// True only when the answer is known *and* it is yes. A badge should never
  /// appear on a maybe.
  bool get isPro => _status?.isPremium ?? false;

  /// Pro, but from the on-device tester switch rather than a purchase.
  ///
  /// Surfaced so the settings card can still say so. Everything else in the
  /// app treats it as plain Pro, which is the point of the switch.
  bool get isTesterAccess => _status?.isTesterAccess ?? false;

  /// Starts listening and resolves the first answer.
  ///
  /// Called once from `main` after [SubscriptionRepository.initialize], so the
  /// first frame of the app already knows — a badge that fades in a second
  /// after launch reads as the app changing its mind about who you are.
  Future<void> load() async {
    _devAccess.addListener(_onDevAccessChanged);

    // The store can change its mind while the app is open — a renewal lands, a
    // subscription lapses, a purchase is made on another device. Watching the
    // stream means those arrive here without anybody polling.
    _changes = _repository.statusChanges.listen(_set);

    await refresh();
  }

  /// Re-asks the store. Used after a purchase or a restore, where waiting for
  /// the stream would leave the screen a beat behind the user's own action.
  Future<void> refresh() async {
    try {
      _set(await _repository.getStatus());
    } catch (_) {
      // A failed lookup must not clear a known-good answer. Losing the store
      // for a moment — no network, RevenueCat unreachable — is not evidence
      // that somebody stopped paying, and treating it as such would flicker
      // the upsell onto a subscriber's screen.
      if (_status == null) _set(SubscriptionStatus.free);
    }
  }

  /// The tester switch is applied inside the repository, so the honest way to
  /// react to it is to ask again rather than to guess the new value here.
  void _onDevAccessChanged() => refresh();

  void _set(SubscriptionStatus next) {
    if (_status != null &&
        _status!.isPremium == next.isPremium &&
        _status!.isTesterAccess == next.isTesterAccess &&
        _status!.expirationDate == next.expirationDate) {
      return;
    }
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _devAccess.removeListener(_onDevAccessChanged);
    _changes?.cancel();
    super.dispose();
  }
}
