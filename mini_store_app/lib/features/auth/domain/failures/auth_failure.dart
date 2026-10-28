/// Application-level authentication failure with a message safe to display.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  /// Whether this failure means the stored session can no longer be trusted.
  bool get requiresReauthentication => false;

  @override
  String toString() => '$runtimeType: $message';
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure(super.message);
}

final class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure(super.message);

  @override
  bool get requiresReauthentication => true;
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure([
    super.message =
        'You appear to be offline. Check your connection and try again.',
  ]);
}

final class TimeoutFailure extends AuthFailure {
  const TimeoutFailure([
    super.message = 'The request timed out. Please try again.',
  ]);
}

final class ServerFailure extends AuthFailure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

final class MalformedResponseFailure extends AuthFailure {
  const MalformedResponseFailure([
    super.message =
        'The server returned an unexpected response. Please try again.',
  ]);

  @override
  bool get requiresReauthentication => true;
}

final class StorageFailure extends AuthFailure {
  const StorageFailure([
    super.message = 'Your session could not be saved. Please try again.',
  ]);

  @override
  bool get requiresReauthentication => true;
}

final class UnexpectedFailure extends AuthFailure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
