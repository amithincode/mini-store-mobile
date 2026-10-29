import 'package:equatable/equatable.dart';

import 'product.dart';

/// One page of products plus the pagination metadata returned by the API.
class ProductPage extends Equatable {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  /// Number of products represented by this page in its original position.
  int get loadedCount => skip + products.length;

  /// Whether the API reports more products after this page.
  bool get hasMore => products.isNotEmpty && loadedCount < total;

  @override
  List<Object?> get props => [products, total, skip, limit];
}
