import 'package:equatable/equatable.dart';

/// A product category returned by `GET /products/categories`.
///
/// The API uses the [slug] in category requests; [name] is only display text.
/// [imageUrl] is a locally resolved preview taken from the category's first
/// product, so it is not part of the raw category payload.
class ProductCategory extends Equatable {
  const ProductCategory({
    required this.slug,
    required this.name,
    this.imageUrl = '',
  });

  final String slug;
  final String name;
  final String imageUrl;

  ProductCategory copyWith({String? slug, String? name, String? imageUrl}) {
    return ProductCategory(
      slug: slug ?? this.slug,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [slug, name, imageUrl];
}
