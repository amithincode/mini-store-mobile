import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../products/data/product_error_mapper.dart';
import '../../../products/domain/failures/product_failure.dart';
import '../../domain/entities/product_category.dart';
import '../models/product_category_model.dart';

abstract interface class CategoryRemoteDataSource {
  Future<List<ProductCategory>> fetchCategories();

  /// Returns the first product image for [slug], or `null` when unavailable.
  Future<String?> fetchPreviewImage(String slug);
}

/// DummyJSON category endpoint using the shared authenticated Dio client.
class DioCategoryRemoteDataSource implements CategoryRemoteDataSource {
  DioCategoryRemoteDataSource(this._dio);

  static const String categoriesPath = '/products/categories';
  static const String categoryProductsPath = '/products/category';

  final Dio _dio;

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    try {
      final response = await _dio.get<Object?>(categoriesPath);
      return ProductCategoryModel.listFromJson(_decoded(response.data));
    } on DioException catch (exception) {
      throw mapProductDioException(exception);
    } on FormatException {
      throw const ProductMalformedFailure();
    } on TypeError {
      throw const ProductMalformedFailure();
    }
  }

  @override
  Future<String?> fetchPreviewImage(String slug) async {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get<Object?>(
        '$categoryProductsPath/${Uri.encodeComponent(trimmed)}',
        queryParameters: const <String, dynamic>{'limit': 1},
      );
      return _firstImage(_decoded(response.data));
    } on DioException catch (exception) {
      throw mapProductDioException(exception);
    } catch (_) {
      // A preview is decorative; malformed payloads simply fall back to the
      // category icon instead of failing the category list.
      return null;
    }
  }

  String? _firstImage(Object? payload) {
    if (payload is! Map) {
      return null;
    }
    final products = payload['products'];
    if (products is! List || products.isEmpty) {
      return null;
    }
    final first = products.first;
    if (first is! Map) {
      return null;
    }

    final thumbnail = first['thumbnail'];
    if (thumbnail is String && thumbnail.trim().isNotEmpty) {
      return thumbnail.trim();
    }

    final images = first['images'];
    if (images is List) {
      for (final image in images) {
        if (image is String && image.trim().isNotEmpty) {
          return image.trim();
        }
      }
    }

    final image = first['image'];
    if (image is String && image.trim().isNotEmpty) {
      return image.trim();
    }
    return null;
  }

  Object? _decoded(Object? data) {
    if (data is String && data.trim().isNotEmpty) {
      return jsonDecode(data);
    }
    return data;
  }
}
