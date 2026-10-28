import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/product.dart';
import '../utils/product_category_label.dart';

/// Compact product tile used by the responsive grid.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.imageCacheWidth,
  });

  final Product product;
  final VoidCallback onTap;

  /// Decode width for the thumbnail, derived from the grid cell width.
  final int? imageCacheWidth;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      productCategoryLabel(product.category).toUpperCase(),
      if (product.brand != null) product.brand!.toUpperCase(),
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.imageBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppNetworkImage(
                        imageUrl: product.imageUrl,
                        semanticLabel: product.title,
                        memCacheWidth: imageCacheWidth,
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _DiscountBadge(
                        label: formatDiscount(product.discountPercentage),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.productMeta,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.productTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(formatPrice(product.price), style: AppTypography.price),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatRating(product.rating),
                        style: AppTypography.rating,
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

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTypography.badge),
    );
  }
}
