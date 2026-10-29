import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cart/presentation/cubit/cart_cubit.dart';
import '../domain/entities/wishlist_item.dart';
import 'cubit/wishlist_cubit.dart';

/// Moves a saved product into the cart and drops it from the wishlist.
///
/// The cart write happens first: if it fails the wishlist is left untouched so
/// the shopper never loses the item they meant to buy.
Future<void> moveWishlistItemToCart(
  BuildContext context,
  WishlistCubit wishlist,
  WishlistItem item,
) async {
  final cart = _maybeCartCubit(context);
  if (cart == null) {
    return;
  }

  final added = await cart.addItem(item.toProduct());
  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!added) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            cart.state.errorMessage ??
                'Could not add this item to your cart. Please try again.',
          ),
        ),
      );
    return;
  }

  final removed = await wishlist.remove(item.productId);
  if (!context.mounted) {
    return;
  }

  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? 'Moved “${item.title}” to your cart.'
              : 'Added to your cart. It is still saved on your wishlist.',
        ),
      ),
    );
}

CartCubit? _maybeCartCubit(BuildContext context) {
  try {
    return BlocProvider.of<CartCubit>(context, listen: false);
  } catch (_) {
    return null;
  }
}
