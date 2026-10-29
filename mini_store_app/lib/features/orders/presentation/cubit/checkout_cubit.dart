import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/place_order_use_case.dart';
import 'checkout_state.dart';

/// Owns the local dummy checkout.
///
/// It snapshots the cart, simulates processing, persists the empty cart, and
/// only then publishes success. Duplicate submissions are blocked.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required CartCubit cart,
    required PlaceOrderUseCase placeOrder,
  }) : _cart = cart,
       _placeOrder = placeOrder,
       super(const CheckoutIdle());

  final CartCubit _cart;
  final PlaceOrderUseCase _placeOrder;

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

    final itemCount = cart.itemCount;
    final total = cart.totalPrice;
    _inFlight = true;
    emit(CheckoutProcessing(itemCount: itemCount, total: total));

    try {
      final order = await _placeOrder(itemCount: itemCount, total: total);
      if (isClosed) {
        return false;
      }

      final cleared = await _cart.clear();
      if (!cleared) {
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
