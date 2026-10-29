/// Thrown when the local cart could not be persisted.
class CartStorageException implements Exception {
  const CartStorageException([
    this.message = 'Could not save your cart. Please try again.',
  ]);

  final String message;

  @override
  String toString() => 'CartStorageException: $message';
}
