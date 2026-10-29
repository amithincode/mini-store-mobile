import '../entities/order.dart';
import '../entities/order_line_item.dart';
import '../services/order_number_generator.dart';

/// Simulates local order processing, then snapshots the confirmed line items.
class PlaceOrderUseCase {
  const PlaceOrderUseCase(
    this._generator, {
    this.processingDelay = const Duration(milliseconds: 1200),
  });

  final OrderNumberGenerator _generator;
  final Duration processingDelay;

  Future<Order> call({required List<OrderLineItem> items}) async {
    if (processingDelay > Duration.zero) {
      await Future<void>.delayed(processingDelay);
    }

    return Order(
      orderNumber: _generator.next(),
      placedAt: DateTime.now(),
      items: List<OrderLineItem>.unmodifiable(items),
    );
  }
}
