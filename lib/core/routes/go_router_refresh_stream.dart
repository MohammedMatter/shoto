import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] (Firebase's auth-state stream) into a [Listenable]
/// so GoRouter can re-evaluate its `redirect` callback whenever auth state
/// changes, e.g. after sign-in or sign-out.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
