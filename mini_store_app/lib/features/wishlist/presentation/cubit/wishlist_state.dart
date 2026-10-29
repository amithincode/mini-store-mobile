import 'package:equatable/equatable.dart';

import '../../domain/entities/wishlist_item.dart';

const Object _unset = Object();

class WishlistState extends Equatable {
  const WishlistState({
    this.items = const <WishlistItem>[],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final List<WishlistItem> items;
  final bool isLoading;

  /// True while a wishlist change is being persisted.
  final bool isMutating;

  /// Last storage error, cleared by the next successful change.
  final String? errorMessage;

  bool get isEmpty => items.isEmpty;

  int get count => items.length;

  bool contains(int productId) {
    return items.any((item) => item.productId == productId);
  }

  WishlistItem? itemFor(int productId) {
    for (final item in items) {
      if (item.productId == productId) {
        return item;
      }
    }
    return null;
  }

  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    bool? isMutating,
    Object? errorMessage = _unset,
  }) {
    return WishlistState(
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
