/// Application-level product failure with a message safe to display.
///
/// Authentication failures stay separate from connectivity failures so the UI
/// never shows "offline" for an expired session.
sealed class ProductFailure implements Exception {
  const ProductFailure(this.message);

  final String message;

  /// Whether the device could not reach the API at all.
  bool get isOffline => false;

  /// Whether the stored session can no longer be trusted.
  bool get requiresReauthentication => false;

  @override
  String toString() => '$runtimeType: $message';
}

final class ProductOfflineFailure extends ProductFailure {
  const ProductOfflineFailure([
    super.message = "You're offline. Check your connection and try again.",
  ]);

  @override
  bool get isOffline => true;
}

final class ProductTimeoutFailure extends ProductFailure {
  const ProductTimeoutFailure([
    super.message = 'The request timed out. Please try again.',
  ]);
}

final class ProductServerFailure extends ProductFailure {
  const ProductServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

final class ProductAuthFailure extends ProductFailure {
  const ProductAuthFailure([
    super.message = 'Your session expired. Please sign in again.',
  ]);

  @override
  bool get requiresReauthentication => true;
}

final class ProductMalformedFailure extends ProductFailure {
  const ProductMalformedFailure([
    super.message = 'The server returned an unexpected response.',
  ]);
}

final class ProductUnexpectedFailure extends ProductFailure {
  const ProductUnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
