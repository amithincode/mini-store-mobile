import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item.dart';

const Object _unset = Object();

class CartState extends Equatable {
  const CartState({
    this.items = const <CartItem>[],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final List<CartItem> items;
  final bool isLoading;

  /// True while a cart change is being persisted.
  final bool isMutating;

  /// Last storage error, cleared by the next successful change.
  final String? errorMessage;

  bool get isEmpty => items.isEmpty;

  /// Total units across all lines, used by the badge and summary.
  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  int get totalQuantity => itemCount;

  double get totalPrice =>
      items.fold(0, (total, item) => total + item.lineTotal);

  int quantityFor(int productId) {
    return items
        .where((item) => item.productId == productId)
        .fold(0, (total, item) => total + item.quantity);
  }

  CartItem? itemFor(int productId) {
    for (final item in items) {
      if (item.productId == productId) {
        return item;
      }
    }
    return null;
  }

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    bool? isMutating,
    Object? errorMessage = _unset,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [items, isLoading, isMutating, errorMessage];
}
