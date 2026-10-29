import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import 'cart_state.dart';
class CartCubit extends Cubit<CartState> { CartCubit(this._repository) : super(const CartState()); final CartRepository _repository;
  Future<void> loadCart() async { try { emit(CartState(items: List.unmodifiable(await _repository.loadCart()))); } catch (_) {} }
  Future<void> addItem(Product product) => _change(product.id, product: product, delta: 1);
  Future<void> increment(int productId) => _change(productId, delta: 1);
  Future<void> decrement(int productId) => _change(productId, delta: -1);
  Future<void> _change(int id, {Product? product, required int delta}) async { final items = [...state.items]; final index = items.indexWhere((item) => item.productId == id); if (index < 0) { if (product == null || delta <= 0) return; items.add(CartItem(productId: product.id, title: product.title, price: product.price, thumbnail: product.imageUrl, quantity: delta)); } else { final next = items[index].quantity + delta; if (next <= 0) { items.removeAt(index); } else { items[index] = items[index].copyWith(quantity: next); } } final updated = CartState(items: List.unmodifiable(items)); emit(updated); try { await _repository.saveCart(updated.items); } catch (_) {} }
}
