import 'dart:async';

import 'package:flutter/material.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream({required Stream<dynamic> stream}) {
    notifyListeners();
    _streamSubscription = stream.asBroadcastStream().listen(
      (event) => notifyListeners(),
    );
  }
  late final StreamSubscription _streamSubscription;

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
