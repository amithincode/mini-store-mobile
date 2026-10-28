import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a cubit stream to GoRouter's [Listenable] refresh mechanism.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (_) => notifyListeners(),
      onDone: notifyListeners,
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
