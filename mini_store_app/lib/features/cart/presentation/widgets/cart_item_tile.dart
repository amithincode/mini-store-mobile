import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/cart_item.dart';

/// One line in the cart with quantity controls and a remove action.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.isBusy,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final bool isBusy;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('cart-item-${item.productId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: AppColors.imageBackground,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: AppNetworkImage(
                      imageUrl: item.thumbnail,
                      semanticLabel: item.title,
                      memCacheWidth: 160,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        key: ValueKey('cart-remove-${item.productId}'),
                        tooltip: 'Remove item',
                        onPressed: isBusy ? null : onRemove,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${formatPrice(item.price)} each',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _QuantityButton(
                        key: ValueKey('cart-decrement-${item.productId}'),
                        icon: Icons.remove_rounded,
                        tooltip: 'Decrease quantity',
                        onPressed: isBusy ? null : onDecrement,
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${item.quantity}',
                          key: ValueKey('cart-quantity-${item.productId}'),
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium,
                        ),
                      ),
                      _QuantityButton(
                        key: ValueKey('cart-increment-${item.productId}'),
                        icon: Icons.add_rounded,
                        tooltip: 'Increase quantity',
                        onPressed: isBusy ? null : onIncrement,
                      ),
                      const Spacer(),
                      Text(
                        formatPrice(item.lineTotal),
                        key: ValueKey('cart-line-total-${item.productId}'),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}
