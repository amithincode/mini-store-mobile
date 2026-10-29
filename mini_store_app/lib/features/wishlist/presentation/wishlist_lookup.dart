import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/wishlist_cubit.dart';

/// Returns the wishlist cubit when the surrounding route provides one.
///
/// Screens such as the storefront can be previewed or tested without the
/// wishlist dependency; in that case heart actions simply do not render.
WishlistCubit? maybeWishlistCubit(BuildContext context) {
  try {
    return BlocProvider.of<WishlistCubit>(context, listen: false);
  } catch (_) {
    return null;
  }
}
