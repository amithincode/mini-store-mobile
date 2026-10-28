import 'package:equatable/equatable.dart';

/// A product shown in the storefront.
///
/// Phase 1 keeps this entity free of JSON parsing and repository concerns.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.brand,
    this.discountPercentage = 0,
  });

  final int id;
  final String title;

  /// Category slug, such as `home-decoration`.
  final String category;
  final double price;
  final double rating;
  final String imageUrl;
  final String? brand;
  final double discountPercentage;

  bool get hasDiscount => discountPercentage > 0;

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    price,
    rating,
    imageUrl,
    brand,
    discountPercentage,
  ];
}
