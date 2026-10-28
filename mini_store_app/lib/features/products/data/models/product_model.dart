import '../../domain/entities/product.dart';

/// Transport model for a single product.
///
/// Parsing is deliberately tolerant: numbers may arrive as int, double, or
/// numeric strings, and optional fields may be missing. Only a missing/invalid
/// product id makes the item unusable.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.imageUrl,
    required this.discountPercentage,
    required this.availabilityStatus,
    required this.images,
    this.brand,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String imageUrl;
  final String? brand;
  final double discountPercentage;
  final String availabilityStatus;
  final List<String> images;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    if (id == null || id <= 0) {
      throw const FormatException('A product is missing its identifier.');
    }

    final images = _readStringList(json['images']);
    final thumbnail = _readString(json['thumbnail']);

    return ProductModel(
      id: id,
      title: _readString(json['title'], fallback: 'Untitled product'),
      description: _readString(json['description']),
      category: _readString(json['category'], fallback: 'uncategorized'),
      price: _readDouble(json['price']) ?? 0,
      rating: _readDouble(json['rating']) ?? 0,
      stock: _readInt(json['stock']) ?? 0,
      imageUrl: thumbnail.isNotEmpty
          ? thumbnail
          : (images.isEmpty ? '' : images.first),
      brand: _readNullableString(json['brand']),
      discountPercentage: _readDouble(json['discountPercentage']) ?? 0,
      availabilityStatus: _readString(json['availabilityStatus']),
      images: images,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      title: product.title,
      description: product.description,
      category: product.category,
      price: product.price,
      rating: product.rating,
      stock: product.stock,
      imageUrl: product.imageUrl,
      brand: product.brand,
      discountPercentage: product.discountPercentage,
      availabilityStatus: product.availabilityStatus,
      images: product.images,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      title: title,
      description: description,
      category: category,
      price: price,
      rating: rating,
      stock: stock,
      imageUrl: imageUrl,
      brand: brand,
      discountPercentage: discountPercentage,
      availabilityStatus: availabilityStatus,
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'rating': rating,
      'stock': stock,
      'thumbnail': imageUrl,
      'brand': brand,
      'discountPercentage': discountPercentage,
      'availabilityStatus': availabilityStatus,
      'images': images,
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    return value is String ? value.trim() : fallback;
  }

  static String? _readNullableString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

  static double? _readDouble(Object? value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return List<String>.unmodifiable(
      value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    );
  }
}
