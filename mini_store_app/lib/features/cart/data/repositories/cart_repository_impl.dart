import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._local);
  final CartLocalDataSource _local;
  @override
  Future<List<CartItem>> loadCart() => _local.load();
  @override
  Future<void> saveCart(List<CartItem> items) => _local.save(items);
}
