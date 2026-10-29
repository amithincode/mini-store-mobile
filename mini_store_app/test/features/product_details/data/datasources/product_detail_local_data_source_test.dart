import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/product_details/data/datasources/product_detail_local_data_source.dart';
import 'package:mini_store_app/features/products/data/models/product_model.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:mini_store_app/features/products/domain/entities/product_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStorage storage;
  late SharedPreferencesProductDetailLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await AppStorage.create();
    local = SharedPreferencesProductDetailLocalDataSource(storage);
  });

  final review = ProductReview(
    rating: 5,
    comment: 'Excellent quality.',
    date: DateTime.utc(2026, 1, 2),
    reviewerName: 'Ana',
    reviewerEmail: 'ana@example.com',
  );

  final product = Product(
    id: 42,
    title: 'Detailed product',
    description: 'A full description.',
    category: 'home-decoration',
    price: 31.5,
    rating: 4.6,
    stock: 8,
    brand: 'Mini',
    discountPercentage: 12,
    availabilityStatus: 'In Stock',
    imageUrl: 'https://example.com/42.webp',
    images: const [
      'https://example.com/42-a.webp',
      'https://example.com/42-b.webp',
    ],
    reviews: [review],
    warrantyInformation: '1 year warranty',
    shippingInformation: 'Ships in 2 days',
    returnPolicy: '30 day returns',
    minimumOrderQuantity: 2,
  );

  test('round-trips every detail field, including reviews', () async {
    await local.save(product);

    final restored = await local.read(42);

    expect(restored, isNotNull);
    expect(restored!.title, product.title);
    expect(restored.rating, product.rating);
    expect(restored.images, product.images);
    expect(restored.warrantyInformation, product.warrantyInformation);
    expect(restored.reviews, hasLength(1));
    expect(restored.reviews.single.reviewerName, 'Ana');
    expect(restored.reviews.single.comment, 'Excellent quality.');
    expect(restored.reviews.single.rating, 5);
  });

  test('keeps details isolated per product id', () async {
    await local.save(product);

    expect(await local.read(42), isNotNull);
    expect(await local.read(43), isNull);
  });

  test('falls back to the cached list item for instant details', () async {
    final listProduct = Product(
      id: 7,
      title: 'List product',
      category: 'beauty',
      price: 9.99,
      rating: 4.2,
      imageUrl: 'https://example.com/7.webp',
    );
    await storage.write<String>(
      'mini_store.products.v1.item.7',
      jsonEncode(ProductModel.fromEntity(listProduct).toJson()),
    );

    final restored = await local.read(7);

    expect(restored, isNotNull);
    expect(restored!.id, 7);
    expect(restored.title, 'List product');
  });

  test('ignores a corrupted detail entry', () async {
    await storage.write<String>('mini_store.product_detail.v1.42', '{not json');

    expect(await local.read(42), isNull);
  });
}
