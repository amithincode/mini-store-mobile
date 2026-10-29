/// Thrown when the local wishlist could not be persisted.
class WishlistStorageException implements Exception {
  const WishlistStorageException([
    this.message = 'Could not save your wishlist. Please try again.',
  ]);

  final String message;

  @override
  String toString() => 'WishlistStorageException: $message';
}
