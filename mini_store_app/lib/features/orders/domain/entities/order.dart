import 'package:equatable/equatable.dart';

import 'order_line_item.dart';

/// A locally generated order summary. No backend order is created.
class Order extends Equatable {
  const Order({
    required this.orderNumber,
    required this.placedAt,
    this.items = const <OrderLineItem>[],
  });

  final String orderNumber;
  final DateTime placedAt;
  final List<OrderLineItem> items;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  double get totalPaid =>
      items.fold(0, (total, item) => total + item.lineTotal);

  @override
  List<Object?> get props => [orderNumber, placedAt, items];
}
