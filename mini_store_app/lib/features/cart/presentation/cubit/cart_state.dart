import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';
class CartState extends Equatable { const CartState({this.items = const []}); final List<CartItem> items; int get itemCount => items.fold(0, (total, item) => total + item.quantity); int quantityFor(int productId) => items.where((item) => item.productId == productId).fold(0, (total, item) => total + item.quantity); @override List<Object?> get props => [items]; }
