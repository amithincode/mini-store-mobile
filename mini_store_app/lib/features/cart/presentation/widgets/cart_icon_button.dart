import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Presentational cart action for the shared app bar.
///
/// Cart behaviour is intentionally out of scope for Phase 1.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: 'Cart',
      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.primaryDark,
      ),
    );
  }
}
