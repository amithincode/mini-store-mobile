import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/failures/wishlist_storage_exception.dart';
import '../../domain/repositories/wishlist_repository.dart';
import 'wishlist_state.dart';

/// Shared, locally persisted wishlist.
///
/// Mirrors the cart cubit: every change is serialized, written to storage
/// first, and only then emitted. A failure leaves the previous wishlist intact.
class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit(this._repository) : super(const WishlistState(isLoading: true));

  final WishlistRepository _repository;

  Future<void> _tail = Future<void>.value();

  /// Restores the saved wishlist on startup.
  Future<void> loadWishlist() {
    return _enqueue<void>(() async {
      if (isClosed) {
        return;
      }

      try {
        final items = _dedupe(await _repository.loadWishlist());
        if (isClosed) {
          return;
        }
        emit(WishlistState(items: List<WishlistItem>.unmodifiable(items)));
      } catch (_) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Your saved wishlist could not be restored.',
          ),
        );
      }
    });
  }

  Future<bool> toggle(Product product) {
    return _enqueue<bool>(() async {
      if (isClosed) {
        return false;
      }
      if (state.contains(product.id)) {
        return _remove(product.id);
      }
      return _add(product);
    });
  }

  Future<bool> add(Product product) {
    return _enqueue<bool>(() async {
      if (isClosed) {
        return false;
      }
      return _add(product);
    });
  }

  Future<bool> remove(int productId) {
    return _enqueue<bool>(() async {
      if (isClosed) {
        return false;
      }
      return _remove(productId);
    });
  }

  Future<bool> _add(Product product) {
    final next = <WishlistItem>[
      WishlistItem.fromProduct(product),
      ...state.items.where((item) => item.productId != product.id),
    ];
    return _persist(next);
  }

  Future<bool> _remove(int productId) {
    final next = state.items
        .where((item) => item.productId != productId)
        .toList(growable: false);
    return _persist(next);
  }

  Future<bool> _persist(List<WishlistItem> next) async {
    if (isClosed) {
      return false;
    }

    if (_sameItems(next, state.items)) {
      if (state.errorMessage != null) {
        emit(state.copyWith(errorMessage: null));
      }
      return true;
    }

    emit(state.copyWith(isMutating: true, errorMessage: null));

    try {
      await _repository.saveWishlist(List<WishlistItem>.unmodifiable(next));
      if (isClosed) {
        return false;
      }
      emit(WishlistState(items: List<WishlistItem>.unmodifiable(next)));
      return true;
    } on WishlistStorageException catch (failure) {
      return _fail(failure.message);
    } catch (_) {
      return _fail(
        'Could not save your wishlist. Your change was not applied.',
      );
    }
  }

  bool _fail(String message) {
    if (!isClosed) {
      emit(state.copyWith(isMutating: false, errorMessage: message));
    }
    return false;
  }

  /// Runs wishlist operations one at a time so overlapping taps cannot race.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static bool _sameItems(List<WishlistItem> a, List<WishlistItem> b) {
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

  static List<WishlistItem> _dedupe(List<WishlistItem> items) {
    final seen = <int>{};
    final result = <WishlistItem>[];
    for (final item in items) {
      if (item.productId <= 0 || !seen.add(item.productId)) {
        continue;
      }
      result.add(item);
    }
    return result;
  }
}
