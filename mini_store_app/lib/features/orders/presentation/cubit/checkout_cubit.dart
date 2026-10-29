import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_line_item.dart';
import '../../domain/usecases/place_order_use_case.dart';
import 'checkout_state.dart';
import 'order_history_cubit.dart';

/// Owns the local dummy checkout.
///
/// It snapshots the cart, saves the order to local history, persists the empty
/// cart, and only then publishes success. If either write fails the cart is
/// left intact so the shopper can retry.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required CartCubit cart,
    required PlaceOrderUseCase placeOrder,
    required OrderHistoryCubit history,
  }) : _cart = cart,
       _placeOrder = placeOrder,
       _history = history,
       super(const CheckoutIdle());

  final CartCubit _cart;
  final PlaceOrderUseCase _placeOrder;
  final OrderHistoryCubit _history;

  bool _inFlight = false;
  Order? _completedOrder;

  Order? get completedOrder => _completedOrder;

  Future<bool> confirmOrder() async {
    if (_inFlight || state is CheckoutProcessing) {
      return false;
    }

    final cart = _cart.state;
    if (cart.items.isEmpty) {
      emit(const CheckoutFailure('Your cart is empty.'));
      return false;
    }

    final lines = cart.items
        .map(
          (item) => OrderLineItem(
            productId: item.productId,
            title: item.title,
            price: item.price,
            thumbnail: item.thumbnail,
            quantity: item.quantity,
          ),
        )
        .toList(growable: false);
    final itemCount = cart.itemCount;
    final total = cart.totalPrice;

    _inFlight = true;
    emit(CheckoutProcessing(itemCount: itemCount, total: total));

    try {
      final order = await _placeOrder(items: lines);
      if (isClosed) {
        return false;
      }

      final saved = await _history.add(order);
      if (!saved) {
        if (!isClosed) {
          emit(
            const CheckoutFailure(
              'Your order could not be saved to My orders. Please try again.',
            ),
          );
        }
        return false;
      }

      final cleared = await _cart.clear();
      if (!cleared) {
        // Roll the saved order back so a retry cannot leave a duplicate in
        // My orders while the cart is still holding the same items.
        await _history.remove(order.orderNumber);
        if (!isClosed) {
          emit(
            const CheckoutFailure(
              'Your order could not be completed because the cart could not '
              'be updated. Please try again.',
            ),
          );
        }
        return false;
      }

      _completedOrder = order;
      if (!isClosed) {
        emit(CheckoutSuccess(order));
      }
      return true;
    } catch (_) {
      if (!isClosed) {
        emit(
          const CheckoutFailure(
            'Something went wrong while placing your order. Please try again.',
          ),
        );
      }
      return false;
    } finally {
      _inFlight = false;
    }
  }

  /// Clears the completed order after the success screen is dismissed.
  void reset() {
    _completedOrder = null;
    if (!isClosed) {
      emit(const CheckoutIdle());
    }
  }
}
