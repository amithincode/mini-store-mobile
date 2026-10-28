import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';

/// UI state for the storefront.
class StoreState extends Equatable {
  const StoreState({
    required this.products,
    this.query = '',
    this.selectedCategory = allCategory,
  });

  static const String allCategory = 'All';

  final List<Product> products;
  final String query;
  final String selectedCategory;

  /// Categories in catalogue order, always starting with "All".
  List<String> get categories {
    final seen = <String>{};
    final result = <String>[allCategory];

    for (final product in products) {
      if (seen.add(product.category)) {
        result.add(product.category);
      }
    }

    return List<String>.unmodifiable(result);
  }

  /// Products matching both the category and the search query.
  List<Product> get visibleProducts {
    final normalizedQuery = query.trim().toLowerCase();

    return products
        .where((product) {
          final matchesCategory =
              selectedCategory == allCategory ||
              product.category == selectedCategory;
          if (!matchesCategory) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          final brand = product.brand?.toLowerCase() ?? '';
          return product.title.toLowerCase().contains(normalizedQuery) ||
              product.category.toLowerCase().contains(normalizedQuery) ||
              brand.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty || selectedCategory != allCategory;

  StoreState copyWith({String? query, String? selectedCategory}) {
    return StoreState(
      products: products,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [products, query, selectedCategory];
}
