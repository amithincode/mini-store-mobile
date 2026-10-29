import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/failures/cart_storage_exception.dart';
import '../../domain/repositories/cart_repository.dart';
import 'cart_state.dart';

/// Shared cart state.
///
/// Every change is serialized, persisted first, and only then emitted. A
/// storage failure keeps the previous cart intact and reports `false` so the
/// UI never shows a false success.
class CartCubit extends Cubit<CartState> {
  CartCubit(this._repository) : super(const CartState(isLoading: true));

  final CartRepository _repository;

  Future<void> _tail = Future<void>.value();

  /// Restores the persisted cart on startup.
  Future<void> loadCart() {
    return _enqueue<void>(() async {
      if (isClosed) {
        return;
      }

      try {
        final items = _dedupe(await _repository.loadCart());
        if (isClosed) {
          return;
        }
        emit(CartState(items: List<CartItem>.unmodifiable(items)));
      } catch (_) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Your saved cart could not be restored.',
          ),
        );
      }
    });
  }

  Future<bool> addItem(Product product) {
    return _mutate((items) {
      final index = items.indexWhere((item) => item.productId == product.id);
      if (index < 0) {
        items.add(
          CartItem(
            productId: product.id,
            title: product.title,
            price: product.price,
            thumbnail: product.imageUrl,
            quantity: 1,
          ),
        );
      } else {
        items[index] = items[index].copyWith(
          quantity: items[index].quantity + 1,
        );
      }
      return items;
    });
  }

  Future<bool> increment(int productId) {
    return _mutate((items) {
      final index = items.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        items[index] = items[index].copyWith(
          quantity: items[index].quantity + 1,
        );
      }
      return items;
    });
  }

  Future<bool> decrement(int productId) {
    return _mutate((items) {
      final index = items.indexWhere((item) => item.productId == productId);
      if (index < 0) {
        return items;
      }
      final next = items[index].quantity - 1;
      if (next <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: next);
      }
      return items;
    });
  }

  Future<bool> remove(int productId) {
    return _mutate(
      (items) => items..removeWhere((item) => item.productId == productId),
    );
  }

  /// Persists an empty cart. Used by checkout before reporting success.
  Future<bool> clear() => _mutate((items) => items..clear());

  Future<bool> _mutate(List<CartItem> Function(List<CartItem> items) build) {
    return _enqueue<bool>(() async {
      if (isClosed) {
        return false;
      }

      final next = build(List<CartItem>.of(state.items));
      if (_sameItems(next, state.items)) {
        if (state.errorMessage != null) {
          emit(state.copyWith(errorMessage: null));
        }
        return true;
      }

      emit(state.copyWith(isMutating: true, errorMessage: null));

      try {
        await _repository.saveCart(List<CartItem>.unmodifiable(next));
        if (isClosed) {
          return false;
        }
        emit(CartState(items: List<CartItem>.unmodifiable(next)));
        return true;
      } on CartStorageException catch (failure) {
        return _fail(failure.message);
      } catch (_) {
        return _fail('Could not save your cart. Your change was not applied.');
      }
    });
  }

  bool _fail(String message) {
    if (!isClosed) {
      emit(state.copyWith(isMutating: false, errorMessage: message));
    }
    return false;
  }

  /// Runs cart operations one at a time so overlapping taps cannot race.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static bool _sameItems(List<CartItem> a, List<CartItem> b) {
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

  static List<CartItem> _dedupe(List<CartItem> items) {
    final byId = <int, CartItem>{};
    for (final item in items) {
      if (item.productId <= 0 || item.quantity <= 0) {
        continue;
      }
      final existing = byId[item.productId];
      byId[item.productId] = existing == null
          ? item
          : existing.copyWith(quantity: existing.quantity + item.quantity);
    }
    return byId.values.toList(growable: false);
  }
}
