import '../../domain/entities/product_page.dart';
import 'product_model.dart';

/// Transport wrapper returned by both product listing and search endpoints.
class ProductListResponseModel {
  const ProductListResponseModel({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<ProductModel> products;
  final int total;
  final int skip;
  final int limit;

  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    if (rawProducts is! List) {
      throw const FormatException('The products payload is missing.');
    }

    final products = <ProductModel>[];
    for (final rawProduct in rawProducts) {
      if (rawProduct is! Map) {
        continue;
      }

      try {
        products.add(
          ProductModel.fromJson(Map<String, dynamic>.from(rawProduct)),
        );
      } on FormatException {
        // A single malformed product must not discard the whole page.
      }
    }

    if (rawProducts.isNotEmpty && products.isEmpty) {
      throw const FormatException('No product could be parsed.');
    }

    return ProductListResponseModel(
      products: List<ProductModel>.unmodifiable(products),
      total: _readInt(json['total']) ?? products.length,
      skip: _readInt(json['skip']) ?? 0,
      limit: _readInt(json['limit']) ?? products.length,
    );
  }

  ProductPage toPage() {
    return ProductPage(
      products: List.unmodifiable(
        products.map((product) => product.toEntity()),
      ),
      total: total,
      skip: skip,
      limit: limit,
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
