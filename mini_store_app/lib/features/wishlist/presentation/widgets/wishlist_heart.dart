import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../products/domain/entities/product.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../wishlist_lookup.dart';

/// Heart action that adds or removes a product from the local wishlist.
///
/// Renders nothing when no [WishlistCubit] is available, so product cards stay
/// usable in isolated previews and tests.
class WishlistHeart extends StatelessWidget {
  const WishlistHeart({super.key, required this.product, this.compact = false});

  final Product product;

  /// Slightly smaller icon for the overlay on product cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cubit = maybeWishlistCubit(context);
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<WishlistCubit, WishlistState>(
      bloc: cubit,
      builder: (context, state) {
        final saved = state.contains(product.id);

        return IconButton(
          key: ValueKey('wishlist-toggle-${product.id}'),
          tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
          onPressed: state.isMutating
              ? null
              : () => _toggle(context, cubit, saved),
          icon: Icon(
            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: compact ? 19 : 21,
            color: saved ? AppColors.error : context.palette.textPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: context.palette.surface.withValues(alpha: 0.94),
            disabledBackgroundColor: context.palette.surface.withValues(
              alpha: 0.7,
            ),
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.18),
          ),
        );
      },
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WishlistCubit cubit,
    bool wasSaved,
  ) async {
    final succeeded = await cubit.toggle(product);
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            succeeded
                ? wasSaved
                      ? 'Removed from wishlist.'
                      : 'Saved to wishlist.'
                : cubit.state.errorMessage ??
                      'Could not update your wishlist. Please try again.',
          ),
        ),
      );
  }
}
