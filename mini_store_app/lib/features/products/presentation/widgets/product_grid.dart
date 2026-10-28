import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../domain/entities/product.dart';
import 'product_card.dart';

/// Responsive product grid with 2 / 3 / 4 / 5 columns.
///
/// The grid is nested inside the page scroll view and sizes its own tiles
/// from the available width, including at larger accessibility text sizes.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = metrics.productColumns;
        final spacing = metrics.gridSpacing;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final imageHeight = itemWidth / 1.05;
        final contentHeight = 128 + (textScale - 1).clamp(0.0, 2.0) * 82;

        return GridView.builder(
          key: const ValueKey('product-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: imageHeight + contentHeight,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              key: ValueKey('product-card-${product.id}'),
              product: product,
              onTap: () => onProductTap(product),
            );
          },
        );
      },
    );
  }
}
