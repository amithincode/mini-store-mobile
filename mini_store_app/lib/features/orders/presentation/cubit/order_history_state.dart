import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

const Object _unset = Object();

class OrderHistoryState extends Equatable {
  const OrderHistoryState({
    this.orders = const <Order>[],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  /// Newest order first.
  final List<Order> orders;
  final bool isLoading;

  /// True while a change is being persisted.
  final bool isMutating;

  /// Last storage error, cleared by the next successful change.
  final String? errorMessage;

  bool get isEmpty => orders.isEmpty;

  int get count => orders.length;

  double get totalSpent =>
      orders.fold(0, (total, order) => total + order.totalPaid);

  OrderHistoryState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? isMutating,
    Object? errorMessage = _unset,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [orders, isLoading, isMutating, errorMessage];
}
