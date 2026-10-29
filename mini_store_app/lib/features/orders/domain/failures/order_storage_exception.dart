/// Thrown when a completed order could not be saved locally.
class OrderStorageException implements Exception {
  const OrderStorageException([
    this.message = 'Could not save your order. Please try again.',
  ]);

  final String message;

  @override
  String toString() => 'OrderStorageException: $message';
}
