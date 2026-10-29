import '../entities/order.dart';

abstract interface class OrderRepository {
  Future<List<Order>> loadOrders();
  Future<void> saveOrders(List<Order> orders);
}
