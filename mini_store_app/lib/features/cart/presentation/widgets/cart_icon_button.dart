import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Presentational cart action for the shared app bar.
///
/// Cart behaviour is intentionally out of scope for Phase 1.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, required this.onPressed, this.badgeCount = 0});

  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: 'Cart',
      icon: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
        child: const Icon(Icons.shopping_cart_outlined, size: 20),
      ),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.primaryDark,
      ),
    );
  }
}
