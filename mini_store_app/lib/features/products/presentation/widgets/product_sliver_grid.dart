import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../domain/entities/product.dart';
import 'product_card.dart';

/// Responsive product grid as a sliver so the page builds cards lazily.
///
/// Columns follow [ResponsiveMetrics.productColumns] using the cross-axis space
/// actually allocated to the grid, which keeps the layout correct inside the
/// shared page gutters, split-screen windows, and browser resizes.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final metrics = ResponsiveMetrics.fromWidth(
          constraints.crossAxisExtent,
        );
        final columns = metrics.productColumns;
        final spacing = metrics.gridSpacing;
        final itemWidth =
            (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
        final imageHeight = itemWidth / 1.05;
        final contentHeight = 128 + (textScale - 1).clamp(0.0, 2.0) * 82;
        final imageCacheWidth = (itemWidth * devicePixelRatio).round();

        return SliverGrid(
          key: const ValueKey('product-grid'),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: imageHeight + contentHeight,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = products[index];
            return ProductCard(
              key: ValueKey('product-card-${product.id}'),
              product: product,
              imageCacheWidth: imageCacheWidth,
              onTap: () => onProductTap(product),
            );
          }, childCount: products.length),
        );
      },
    );
  }
}
