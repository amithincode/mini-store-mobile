import 'package:mini_store_app/features/products/domain/entities/product.dart';

const List<Product> testProducts = <Product>[
  Product(
    id: 1,
    title: 'Essence Mascara Lash Princess',
    description: 'A volumizing mascara.',
    category: 'beauty',
    price: 9.99,
    rating: 2.56,
    stock: 99,
    brand: 'Essence',
    discountPercentage: 10.48,
    availabilityStatus: 'In Stock',
    imageUrl: 'https://example.com/mascara.webp',
    images: <String>['https://example.com/mascara-1.webp'],
  ),
  Product(
    id: 2,
    title: 'iPhone 13 Pro',
    description: 'A flagship phone.',
    category: 'smartphones',
    price: 1099.99,
    rating: 4.12,
    stock: 5,
    brand: 'Apple',
    discountPercentage: 9.37,
    availabilityStatus: 'Low Stock',
    imageUrl: 'https://example.com/iphone.webp',
  ),
  Product(
    id: 3,
    title: 'Cooking Oil',
    description: 'Everyday cooking oil.',
    category: 'groceries',
    price: 4.99,
    rating: 4.8,
    stock: 0,
    discountPercentage: 9.33,
    availabilityStatus: 'Out of Stock',
    imageUrl: 'https://example.com/oil.webp',
  ),
  Product(
    id: 4,
    title: 'Apple',
    description: 'A crisp apple.',
    category: 'groceries',
    price: 1.99,
    rating: 4.19,
    stock: 12,
    discountPercentage: 12.62,
    availabilityStatus: 'In Stock',
    imageUrl: 'https://example.com/apple.webp',
  ),
];

Product testProduct(int id) {
  return Product(
    id: id,
    title: 'Product $id',
    description: 'Description for product $id.',
    category: 'groceries',
    price: id + 0.99,
    rating: 4,
    stock: 10,
    brand: 'Brand $id',
    discountPercentage: 5,
    availabilityStatus: 'In Stock',
    imageUrl: 'https://example.com/product-$id.webp',
  );
}

/// Generates [count] products starting at [startId].
List<Product> testProductsFrom(int startId, int count) {
  return List<Product>.generate(
    count,
    (index) => testProduct(startId + index),
    growable: false,
  );
}
