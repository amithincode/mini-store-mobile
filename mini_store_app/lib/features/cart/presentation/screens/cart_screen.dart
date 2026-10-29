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
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../orders/presentation/cubit/checkout_cubit.dart';
import '../../../orders/presentation/cubit/checkout_state.dart';
import '../../../wishlist/presentation/widgets/wishlist_suggestions.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_item_tile.dart';

/// The Cart bottom-navigation tab.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Cart', subtitle: 'Review your items'),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const AppLoadingView(message: 'Restoring your cart…');
          }

          if (state.items.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                        ),
                        child: _InlineError(message: state.errorMessage!),
                      ),
                    AppEmptyView(
                      title: 'Your cart is empty',
                      message:
                          'Browse the storefront and add something you like. '
                          'Your cart will be saved automatically.',
                      icon: Icons.shopping_cart_outlined,
                      actionLabel: 'Continue shopping',
                      onAction: onContinueShopping,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: WishlistSuggestions(),
                    ),
                  ],
                ),
              ),
            );
          }

          return _FilledCart(
            state: state,
            onContinueShopping: onContinueShopping,
          );
        },
      ),
    );
  }
}

class _FilledCart extends StatelessWidget {
  const _FilledCart({required this.state, required this.onContinueShopping});

  final CartState state;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('cart-list'),
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            children: [
              ...state.items.map(
                (item) => CartItemTile(
                  item: item,
                  isBusy: state.isMutating,
                  onIncrement: () => _runCartChange(
                    context,
                    () => context.read<CartCubit>().increment(item.productId),
                  ),
                  onDecrement: () => _runCartChange(
                    context,
                    () => context.read<CartCubit>().decrement(item.productId),
                  ),
                  onRemove: () => _runCartChange(
                    context,
                    () => context.read<CartCubit>().remove(item.productId),
                  ),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _InlineError(message: state.errorMessage!),
              ],
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: onContinueShopping,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Continue shopping'),
              ),
              const SizedBox(height: AppSpacing.md),
              const WishlistSuggestions(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        _CartSummary(state: state),
      ],
    );
  }

  Future<void> _runCartChange(
    BuildContext context,
    Future<bool> Function() change,
  ) async {
    final succeeded = await change();
    if (succeeded || !context.mounted) {
      return;
    }

    final message =
        context.read<CartCubit>().state.errorMessage ??
        'Could not update your cart. Please try again.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BlocBuilder<CheckoutCubit, CheckoutState>(
            builder: (context, checkout) {
              final processing = checkout is CheckoutProcessing;
              final busy = processing || state.isMutating;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${state.itemCount} '
                          '${state.itemCount == 1 ? 'unit' : 'units'}',
                          key: const ValueKey('cart-total-units'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                      Text('Total', style: AppTypography.bodyMedium),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        formatPrice(state.totalPrice),
                        key: const ValueKey('cart-total-price'),
                        style: AppTypography.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const ValueKey('cart-place-order'),
                    onPressed: busy ? null : () => _confirmOrder(context),
                    icon: processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_outline_rounded),
                    label: Text(processing ? 'Placing order…' : 'Place order'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context) async {
    final cart = context.read<CartCubit>();
    if (cart.state.items.isEmpty) {
      return;
    }

    final checkout = context.read<CheckoutCubit>();
    if (checkout.state is CheckoutProcessing) {
      return;
    }

    final itemCount = cart.state.itemCount;
    final total = cart.state.totalPrice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm your order'),
        content: Text(
          'You are about to place an order for $itemCount '
          '${itemCount == 1 ? 'item' : 'items'} '
          'totalling ${formatPrice(total)}.\n\n'
          'This is a local demo checkout — no payment is taken.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('checkout-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('checkout-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final succeeded = await checkout.confirmOrder();
    if (!context.mounted) {
      return;
    }

    if (succeeded) {
      context.pushNamed(AppRoutes.orderSuccessName);
      return;
    }

    final state = checkout.state;
    final message = state is CheckoutFailure
        ? state.message
        : 'Your order could not be completed. Please try again.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
