import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order.dart';
import '../../domain/failures/order_storage_exception.dart';
import '../../domain/repositories/order_repository.dart';
import 'order_history_state.dart';

/// Locally persisted list of completed purchases.
class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  OrderHistoryCubit(this._repository)
    : super(const OrderHistoryState(isLoading: true));

  final OrderRepository _repository;

  Future<void> _tail = Future<void>.value();

  /// Restores saved orders on startup.
  Future<void> loadOrders() {
    return _enqueue<void>(() async {
      if (isClosed) {
        return;
      }

      try {
        final orders = _dedupe(await _repository.loadOrders());
        if (isClosed) {
          return;
        }
        emit(OrderHistoryState(orders: List<Order>.unmodifiable(orders)));
      } catch (_) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Your saved orders could not be restored.',
          ),
        );
      }
    });
  }

  /// Saves a completed order at the top of the history.
  Future<bool> add(Order order) {
    return _enqueue<bool>(() async {
      if (isClosed) {
        return false;
      }

      final next = <Order>[
        order,
        ...state.orders.where(
          (existing) => existing.orderNumber != order.orderNumber,
        ),
      ];
      return _persist(next);
    });
  }

  /// Removes an order again when checkout has to roll back.
  Future<bool> remove(String orderNumber) {
    return _enqueue<bool>(() async {
      if (isClosed) {
        return false;
      }

      final next = state.orders
          .where((order) => order.orderNumber != orderNumber)
          .toList(growable: false);
      return _persist(next);
    });
  }

  Future<bool> _persist(List<Order> next) async {
    if (isClosed) {
      return false;
    }

    if (_sameOrders(next, state.orders)) {
      if (state.errorMessage != null) {
        emit(state.copyWith(errorMessage: null));
      }
      return true;
    }

    emit(state.copyWith(isMutating: true, errorMessage: null));

    try {
      await _repository.saveOrders(List<Order>.unmodifiable(next));
      if (isClosed) {
        return false;
      }
      emit(OrderHistoryState(orders: List<Order>.unmodifiable(next)));
      return true;
    } on OrderStorageException catch (failure) {
      return _fail(failure.message);
    } catch (_) {
      return _fail('Could not save your order. Please try again.');
    }
  }

  bool _fail(String message) {
    if (!isClosed) {
      emit(state.copyWith(isMutating: false, errorMessage: message));
    }
    return false;
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static bool _sameOrders(List<Order> a, List<Order> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  static List<Order> _dedupe(List<Order> orders) {
    final seen = <String>{};
    final result = <Order>[];
    for (final order in orders) {
      if (order.orderNumber.isEmpty || !seen.add(order.orderNumber)) {
        continue;
      }
      result.add(order);
    }
    return result;
  }
}
