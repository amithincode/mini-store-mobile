import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';

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
    required this.reviews,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.returnPolicy,
    required this.minimumOrderQuantity,
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
  final List<ProductReview> reviews;
  final String warrantyInformation;
  final String shippingInformation;
  final String returnPolicy;
  final int minimumOrderQuantity;

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
      reviews: _readReviews(json['reviews']),
      warrantyInformation: _readString(json['warrantyInformation']),
      shippingInformation: _readString(json['shippingInformation']),
      returnPolicy: _readString(json['returnPolicy']),
      minimumOrderQuantity: _readInt(json['minimumOrderQuantity']) ?? 1,
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
      reviews: product.reviews,
      warrantyInformation: product.warrantyInformation,
      shippingInformation: product.shippingInformation,
      returnPolicy: product.returnPolicy,
      minimumOrderQuantity: product.minimumOrderQuantity,
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
      reviews: reviews,
      warrantyInformation: warrantyInformation,
      shippingInformation: shippingInformation,
      returnPolicy: returnPolicy,
      minimumOrderQuantity: minimumOrderQuantity,
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
      'reviews': reviews.map(ProductReviewModel.fromEntity).map((review) => review.toJson()).toList(),
      'warrantyInformation': warrantyInformation,
      'shippingInformation': shippingInformation,
      'returnPolicy': returnPolicy,
      'minimumOrderQuantity': minimumOrderQuantity,
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

  static List<ProductReview> _readReviews(Object? value) {
    if (value is! List) return const <ProductReview>[];
    return List<ProductReview>.unmodifiable(value.whereType<Map>().map((item) {
      return ProductReviewModel.fromJson(Map<String, dynamic>.from(item)).toEntity();
    }));
  }
}

class ProductReviewModel {
  const ProductReviewModel({required this.rating, required this.comment, required this.date, required this.reviewerName, this.reviewerEmail});
  final int rating;
  final String comment;
  final DateTime date;
  final String reviewerName;
  final String? reviewerEmail;
  factory ProductReviewModel.fromJson(Map<String, dynamic> json) => ProductReviewModel(
    rating: (json['rating'] as num?)?.round() ?? 0,
    comment: (json['comment'] as String? ?? '').trim(),
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    reviewerName: (json['reviewerName'] as String? ?? 'Anonymous').trim(),
    reviewerEmail: json['reviewerEmail'] as String?,
  );
  factory ProductReviewModel.fromEntity(ProductReview review) => ProductReviewModel(rating: review.rating, comment: review.comment, date: review.date, reviewerName: review.reviewerName, reviewerEmail: review.reviewerEmail);
  ProductReview toEntity() => ProductReview(rating: rating, comment: comment, date: date, reviewerName: reviewerName, reviewerEmail: reviewerEmail);
  Map<String, dynamic> toJson() => {'rating': rating, 'comment': comment, 'date': date.toUtc().toIso8601String(), 'reviewerName': reviewerName, 'reviewerEmail': reviewerEmail};
}
