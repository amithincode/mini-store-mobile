import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StorePromoBanner extends StatelessWidget {
  const StorePromoBanner({
    super.key,
    required this.onShopNow,
    required this.height,
  });

  static const String _asset = 'assets/images/store_promo_banner.png';

  final VoidCallback onShopNow;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mini Store — Everyday essentials',
      child: SizedBox(
        height: height - 10,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              ),
              Image.asset(
                _asset,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShopNow,
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
