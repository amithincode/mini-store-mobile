import 'package:equatable/equatable.dart';

/// A locally generated order summary. No backend order is created.
class Order extends Equatable {
  const Order({
    required this.orderNumber,
    required this.itemCount,
    required this.totalPaid,
    required this.placedAt,
  });

  final String orderNumber;
  final int itemCount;
  final double totalPaid;
  final DateTime placedAt;

  @override
  List<Object?> get props => [orderNumber, itemCount, totalPaid, placedAt];
}
