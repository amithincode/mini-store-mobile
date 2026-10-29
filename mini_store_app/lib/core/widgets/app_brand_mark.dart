import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand mark shared by the app bar and standalone screens.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.size = 36,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
  });

  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.shopping_bag_rounded,
        color: foregroundColor,
        size: size * 0.55,
      ),
    );
  }
}
