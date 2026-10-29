import 'package:equatable/equatable.dart';

import 'product_review.dart';

/// A product shown in the storefront.
///
/// Pure Dart: JSON parsing belongs to the data layer and is mapped into this
/// entity by the repository.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.description = '',
    this.stock = 0,
    this.brand,
    this.discountPercentage = 0,
    this.availabilityStatus = '',
    this.images = const <String>[],
    this.reviews = const <ProductReview>[],
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.returnPolicy = '',
    this.minimumOrderQuantity = 1,
  });

  final int id;
  final String title;
  final String description;

  /// Category slug, such as `home-decoration`.
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String imageUrl;
  final String? brand;
  final double discountPercentage;
  final String availabilityStatus;

  /// Additional gallery images. The thumbnail is not repeated here.
  final List<String> images;
  final List<ProductReview> reviews;
  final String warrantyInformation;
  final String shippingInformation;
  final String returnPolicy;
  final int minimumOrderQuantity;

  bool get hasDiscount => discountPercentage > 0;

  bool get isInStock => stock > 0;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    price,
    rating,
    stock,
    imageUrl,
    brand,
    discountPercentage,
    availabilityStatus,
    images,
    reviews,
    warrantyInformation,
    shippingInformation,
    returnPolicy,
    minimumOrderQuantity,
  ];
}
