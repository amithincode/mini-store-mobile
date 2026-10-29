import '../entities/cart_item.dart';

abstract interface class CartRepository {
  Future<List<CartItem>> loadCart();
  Future<void> saveCart(List<CartItem> items);
}
