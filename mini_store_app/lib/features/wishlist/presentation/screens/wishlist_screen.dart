import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/wishlist_item.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../wishlist_actions.dart';
import '../wishlist_lookup.dart';

/// Full list of products saved on this device.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = maybeWishlistCubit(context);

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Wishlist',
        subtitle: 'Saved for later',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: cubit == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppEmptyView(
                  title: 'Wishlist unavailable',
                  message: 'Your saved products could not be loaded.',
                  icon: Icons.favorite_border_rounded,
                ),
              ),
            )
          : BlocBuilder<WishlistCubit, WishlistState>(
              bloc: cubit,
              builder: (context, state) {
                if (state.isLoading) {
                  return const AppLoadingView(
                    message: 'Restoring your wishlist…',
                  );
                }

                if (state.items.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppEmptyView(
                        title: 'Your wishlist is empty',
                        message:
                            'Tap the heart on any product to save it here for '
                            'later.',
                        icon: Icons.favorite_border_rounded,
                        actionLabel: 'Continue shopping',
                        onAction: () => _goBack(context),
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.separated(
                      key: const ValueKey('wishlist-list'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.lg,
                      ),
                      itemCount: state.items.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _Header(
                            count: state.count,
                            errorMessage: state.errorMessage,
                          );
                        }

                        final item = state.items[index - 1];
                        return _WishlistTile(
                          item: item,
                          busy: state.isMutating,
                          onAdd: () =>
                              moveWishlistItemToCart(context, cubit, item),
                          onRemove: () => _remove(context, cubit, item),
                          onOpen: () => _openProduct(context, item.productId),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  static Future<void> _remove(
    BuildContext context,
    WishlistCubit cubit,
    WishlistItem item,
  ) async {
    final removed = await cubit.remove(item.productId);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            removed
                ? 'Removed “${item.title}” from your wishlist.'
                : cubit.state.errorMessage ??
                      'Could not update your wishlist. Please try again.',
          ),
        ),
      );
  }

  static void _openProduct(BuildContext context, int productId) {
    GoRouter.maybeOf(context)?.pushNamed(
      AppRoutes.productDetailName,
      pathParameters: {'id': productId.toString()},
    );
  }

  static void _goBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, this.errorMessage});

  final int count;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$count ${count == 1 ? 'item' : 'items'} saved on this device',
          style: AppTypography.bodySmall.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorMessage!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xxs),
      ],
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({
    required this.item,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
    required this.onOpen,
  });

  final WishlistItem item;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Card(
      key: ValueKey('wishlist-item-${item.productId}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 86,
                  height: 86,
                  color: palette.imageBackground,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AppNetworkImage(
                    imageUrl: item.thumbnail,
                    semanticLabel: item.title,
                    memCacheWidth: 220,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.replaceAll('-', ' ').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      formatPrice(item.price),
                      style: AppTypography.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Remove from wishlist',
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.error,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add to cart',
                    onPressed: busy ? null : onAdd,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: palette.primaryContainer,
                      foregroundColor: palette.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
