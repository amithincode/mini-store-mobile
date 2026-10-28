import 'package:mini_store_app/features/products/domain/entities/product.dart';

const List<Product> testProducts = <Product>[
  Product(
    id: 1,
    title: 'Essence Mascara Lash Princess',
    category: 'beauty',
    price: 9.99,
    rating: 2.56,
    brand: 'Essence',
    discountPercentage: 10.48,
    imageUrl: 'https://example.com/mascara.webp',
  ),
  Product(
    id: 2,
    title: 'iPhone 13 Pro',
    category: 'smartphones',
    price: 1099.99,
    rating: 4.12,
    brand: 'Apple',
    discountPercentage: 9.37,
    imageUrl: 'https://example.com/iphone.webp',
  ),
  Product(
    id: 3,
    title: 'Cooking Oil',
    category: 'groceries',
    price: 4.99,
    rating: 4.8,
    discountPercentage: 9.33,
    imageUrl: 'https://example.com/oil.webp',
  ),
  Product(
    id: 4,
    title: 'Apple',
    category: 'groceries',
    price: 1.99,
    rating: 4.19,
    discountPercentage: 12.62,
    imageUrl: 'https://example.com/apple.webp',
  ),
];
