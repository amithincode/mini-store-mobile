import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/wishlist_item.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../wishlist_actions.dart';
import '../wishlist_lookup.dart';

/// Horizontal wishlist preview shown on the Cart tab.
///
/// Renders nothing when the wishlist is empty or unavailable, so the cart keeps
/// its focused layout.
class WishlistSuggestions extends StatelessWidget {
  const WishlistSuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = maybeWishlistCubit(context);
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<WishlistCubit, WishlistState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = state.items.take(8).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'From your wishlist',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openWishlist(context),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _SuggestionCard(
                    item: item,
                    busy: state.isMutating,
                    onAdd: () => moveWishlistItemToCart(context, cubit, item),
                    onOpen: () => _openProduct(context, item.productId),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static void _openWishlist(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    router?.pushNamed(AppRoutes.wishlistName);
  }

  static void _openProduct(BuildContext context, int productId) {
    final router = GoRouter.maybeOf(context);
    router?.pushNamed(
      AppRoutes.productDetailName,
      pathParameters: {'id': productId.toString()},
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.busy,
    required this.onAdd,
    required this.onOpen,
  });

  final WishlistItem item;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: 156,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.imageBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: AppNetworkImage(
                        imageUrl: item.thumbnail,
                        semanticLabel: item.title,
                        memCacheWidth: 240,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.productTitle,
                ),
                const SizedBox(height: 2),
                Text(formatPrice(item.price), style: AppTypography.price),
                const SizedBox(height: AppSpacing.xxs),
                FilledButton(
                  onPressed: busy ? null : onAdd,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Add to cart'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
