import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._local);

  final OrderLocalDataSource _local;

  @override
  Future<List<Order>> loadOrders() => _local.load();

  @override
  Future<void> saveOrders(List<Order> orders) => _local.save(orders);
}
