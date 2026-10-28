import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/products/data/models/product_list_response_model.dart';
import 'package:mini_store_app/features/products/data/models/product_model.dart';

void main() {
  group('ProductModel', () {
    test('parses a complete product payload', () {
      final model = ProductModel.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Essence Mascara Lash Princess',
        'description': 'A product description',
        'category': 'beauty',
        'price': 9.99,
        'discountPercentage': 10.48,
        'rating': 2.56,
        'stock': 99,
        'brand': 'Essence',
        'availabilityStatus': 'In Stock',
        'thumbnail': 'https://cdn.example.com/thumbnail.webp',
        'images': <String>['https://cdn.example.com/1.webp'],
      });

      expect(model.id, 1);
      expect(model.title, 'Essence Mascara Lash Princess');
      expect(model.price, 9.99);
      expect(model.stock, 99);
      expect(model.images, hasLength(1));

      final product = model.toEntity();
      expect(product.id, 1);
      expect(product.hasDiscount, isTrue);
      expect(product.isInStock, isTrue);
      expect(product.availabilityStatus, 'In Stock');
    });

    test('accepts numeric strings and whole-number doubles', () {
      final model = ProductModel.fromJson(<String, dynamic>{
        'id': '7',
        'title': '  Test Product  ',
        'price': '12.5',
        'rating': 4,
        'stock': 3.0,
        'discountPercentage': '2.5',
      });

      expect(model.id, 7);
      expect(model.title, 'Test Product');
      expect(model.price, 12.5);
      expect(model.rating, 4);
      expect(model.stock, 3);
      expect(model.discountPercentage, 2.5);
    });

    test('falls back safely for missing optional fields', () {
      final model = ProductModel.fromJson(<String, dynamic>{
        'id': 2,
        'title': 'Minimal',
        'images': <String>['https://cdn.example.com/first.webp'],
      });

      expect(model.description, isEmpty);
      expect(model.category, 'uncategorized');
      expect(model.price, 0);
      expect(model.rating, 0);
      expect(model.brand, isNull);
      expect(model.availabilityStatus, isEmpty);
      expect(model.imageUrl, 'https://cdn.example.com/first.webp');
    });

    test('uses the thumbnail before the gallery', () {
      final model = ProductModel.fromJson(<String, dynamic>{
        'id': 3,
        'thumbnail': 'https://cdn.example.com/thumb.webp',
        'images': <String>['https://cdn.example.com/gallery.webp'],
      });

      expect(model.imageUrl, 'https://cdn.example.com/thumb.webp');
    });

    test('rejects a product without a valid id', () {
      expect(
        () => ProductModel.fromJson(<String, dynamic>{'title': 'Missing id'}),
        throwsFormatException,
      );
      expect(
        () => ProductModel.fromJson(<String, dynamic>{'id': 0}),
        throwsFormatException,
      );
    });
  });

  group('ProductListResponseModel', () {
    test('parses the wrapper and maps to a page', () {
      final response = ProductListResponseModel.fromJson(<String, dynamic>{
        'products': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'title': 'One', 'price': 2},
          <String, dynamic>{'id': 2, 'title': 'Two', 'price': 3},
        ],
        'total': 194,
        'skip': 0,
        'limit': 10,
      });

      final page = response.toPage();
      expect(page.products, hasLength(2));
      expect(page.products.first.title, 'One');
      expect(page.total, 194);
      expect(page.hasMore, isTrue);
    });

    test('skips malformed individual products', () {
      final response = ProductListResponseModel.fromJson(<String, dynamic>{
        'products': <Object?>[
          <String, dynamic>{'id': 1, 'title': 'Valid'},
          'not a map',
          <String, dynamic>{'title': 'Missing id'},
        ],
        'total': 3,
        'skip': 0,
        'limit': 10,
      });

      expect(response.products, hasLength(1));
      expect(response.products.single.id, 1);
    });

    test('rejects a missing or unusable products list', () {
      expect(
        () => ProductListResponseModel.fromJson(<String, dynamic>{'total': 3}),
        throwsFormatException,
      );
      expect(
        () => ProductListResponseModel.fromJson(<String, dynamic>{
          'products': <Object?>['bad', 2],
        }),
        throwsFormatException,
      );
    });

    test('tolerates missing pagination metadata', () {
      final response = ProductListResponseModel.fromJson(<String, dynamic>{
        'products': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'title': 'One'},
        ],
      });

      expect(response.total, 1);
      expect(response.skip, 0);
      expect(response.limit, 1);
    });
  });
}
