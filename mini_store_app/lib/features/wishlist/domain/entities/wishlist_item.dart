import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product.dart';

/// A product the shopper saved for later.
///
/// The entity keeps a snapshot of the product so wishlist previews on the
/// Account and Cart tabs render without another network request.
class WishlistItem extends Equatable {
  const WishlistItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.rating,
    required this.category,
    required this.addedAt,
  });

  factory WishlistItem.fromProduct(Product product, {DateTime? addedAt}) {
    return WishlistItem(
      productId: product.id,
      title: product.title,
      price: product.price,
      thumbnail: product.imageUrl,
      rating: product.rating,
      category: product.category,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  final int productId;
  final String title;
  final double price;
  final String thumbnail;
  final double rating;
  final String category;
  final DateTime addedAt;

  /// Rebuilds the product needed by the cart when the shopper moves an item
  /// out of the wishlist. Stock is not checked by the cart, so a neutral value
  /// is enough here.
  Product toProduct() {
    return Product(
      id: productId,
      title: title,
      category: category,
      price: price,
      rating: rating,
      imageUrl: thumbnail,
      stock: 1,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    title,
    price,
    thumbnail,
    rating,
    category,
    addedAt,
  ];
}
