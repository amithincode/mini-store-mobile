import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({required this.productId, required this.title, required this.price, required this.thumbnail, required this.quantity});
  final int productId;
  final String title;
  final double price;
  final String thumbnail;
  final int quantity;
  CartItem copyWith({int? quantity}) => CartItem(productId: productId, title: title, price: price, thumbnail: thumbnail, quantity: quantity ?? this.quantity);
  @override
  List<Object?> get props => [productId, title, price, thumbnail, quantity];
}
