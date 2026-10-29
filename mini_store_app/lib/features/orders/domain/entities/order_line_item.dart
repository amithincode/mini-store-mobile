import 'package:equatable/equatable.dart';

/// One purchased line inside a locally saved order.
class OrderLineItem extends Equatable {
  const OrderLineItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.quantity,
  });

  final int productId;
  final String title;
  final double price;
  final String thumbnail;
  final int quantity;

  double get lineTotal => price * quantity;

  @override
  List<Object?> get props => [productId, title, price, thumbnail, quantity];
}
