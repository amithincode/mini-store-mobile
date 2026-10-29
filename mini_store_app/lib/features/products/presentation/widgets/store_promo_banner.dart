import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Promotional banner shown above the product section.
class StorePromoBanner extends StatelessWidget {
  const StorePromoBanner({
    super.key,
    required this.onShopNow,
    required this.height,
  });

  final VoidCallback onShopNow;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -46,
            top: -52,
            child: _DecorativeCircle(size: 190, opacity: 0.09),
          ),
          const Positioned(
            right: 76,
            bottom: -70,
            child: _DecorativeCircle(size: 170, opacity: 0.06),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final showIllustration = constraints.maxWidth >= 560;
              final metrics = constraints.maxWidth < 420 ? 20.0 : 28.0;

              return Padding(
                padding: EdgeInsets.all(metrics),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'WEEKEND DROP',
                              style: AppTypography.badge,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Upgrade your everyday',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontSize: 23,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Up to 30% off curated essentials.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton(
                            onPressed: onShopNow,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Shop the edit'),
                          ),
                        ],
                      ),
                    ),
                    if (showIllustration) ...[
                      const SizedBox(width: AppSpacing.lg),
                      const Icon(
                        Icons.shopping_bag_rounded,
                        size: 112,
                        color: Color(0x33FFFFFF),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
