import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/product.dart';
import 'product_card.dart';

/// Keys already sent to the image cache, per decode width and product.
final Set<String> _prefetchedImages = <String>{};

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

        _prefetchFirstImages(
          context,
          products,
          imageCacheWidth: imageCacheWidth,
        );

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

  /// Warms the image cache for the first visible batch once the grid has
  /// measured its real cell width, so detail and re-entry feel instant.
  void _prefetchFirstImages(
    BuildContext context,
    List<Product> products, {
    required int imageCacheWidth,
  }) {
    if (kIsWeb) {
      return;
    }

    final pending = <Product>[];
    for (final product in products) {
      final url = product.imageUrl.trim();
      if (url.isEmpty) {
        continue;
      }
      final key = '$imageCacheWidth:${product.id}:$url';
      if (_prefetchedImages.add(key)) {
        pending.add(product);
      }
      if (pending.length == 12) {
        break;
      }
    }

    if (pending.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final product in pending) {
        precacheImage(
          appNetworkImageProvider(
            product.imageUrl,
            memCacheWidth: imageCacheWidth,
          ),
          context,
          onError: (_, _) {},
        );
      }
    });
  }
}
