import 'dart:async';

/// Event published when a stored session can no longer be renewed.
class SessionExpirationEvent {
  const SessionExpirationEvent(this.message);

  final String message;
}

/// Decouples the network layer from the authentication cubit and router.
///
/// The interceptor publishes an event; the cubit reacts and the router follows
/// the cubit state. No widget or Dio callback needs a `BuildContext`.
class SessionExpirationNotifier {
  final StreamController<SessionExpirationEvent> _controller =
      StreamController<SessionExpirationEvent>.broadcast();

  Stream<SessionExpirationEvent> get stream => _controller.stream;

  void notifyExpired(String message) {
    if (!_controller.isClosed) {
      _controller.add(SessionExpirationEvent(message));
    }
  }

  Future<void> dispose() => _controller.close();
}
