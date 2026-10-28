import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand mark shared by the app bar and standalone screens.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
