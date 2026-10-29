import '../entities/order.dart';
import '../services/order_number_generator.dart';

/// Simulates local order processing, then snapshots the confirmed totals.
class PlaceOrderUseCase {
  const PlaceOrderUseCase(
    this._generator, {
    this.processingDelay = const Duration(milliseconds: 1200),
  });

  final OrderNumberGenerator _generator;
  final Duration processingDelay;

  Future<Order> call({required int itemCount, required double total}) async {
    if (processingDelay > Duration.zero) {
      await Future<void>.delayed(processingDelay);
    }

    return Order(
      orderNumber: _generator.next(),
      itemCount: itemCount,
      totalPaid: total,
      placedAt: DateTime.now(),
    );
  }
}
