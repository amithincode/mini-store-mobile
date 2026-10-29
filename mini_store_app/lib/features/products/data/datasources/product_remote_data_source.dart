import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/failures/product_failure.dart';
import '../models/product_list_response_model.dart';
import '../product_error_mapper.dart';

/// Remote product contract used by the repository.
abstract interface class ProductRemoteDataSource {
  Future<ProductListResponseModel> fetchProducts({
    required int skip,
    required int limit,
  });

  Future<ProductListResponseModel> searchProducts({
    required String query,
    required int skip,
    required int limit,
  });

  Future<ProductListResponseModel> fetchCategoryProducts({
    required String slug,
    required int skip,
    required int limit,
  });
}

/// DummyJSON product endpoints using the shared authenticated Dio client.
class DioProductRemoteDataSource implements ProductRemoteDataSource {
  DioProductRemoteDataSource(this._dio);

  static const String productsPath = '/products';
  static const String searchPath = '/products/search';
  static const String categoriesPath = '/products/category';

  final Dio _dio;

  @override
  Future<ProductListResponseModel> fetchProducts({
    required int skip,
    required int limit,
  }) {
    return _get(
      productsPath,
      queryParameters: <String, dynamic>{'limit': limit, 'skip': skip},
    );
  }

  @override
  Future<ProductListResponseModel> searchProducts({
    required String query,
    required int skip,
    required int limit,
  }) {
    return _get(
      searchPath,
      queryParameters: <String, dynamic>{
        'q': query,
        'limit': limit,
        'skip': skip,
      },
    );
  }

  @override
  Future<ProductListResponseModel> fetchCategoryProducts({
    required String slug,
    required int skip,
    required int limit,
  }) {
    return _get(
      '$categoriesPath/${Uri.encodeComponent(slug)}',
      queryParameters: <String, dynamic>{'limit': limit, 'skip': skip},
    );
  }

  Future<ProductListResponseModel> _get(
    String path, {
    required Map<String, dynamic> queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return ProductListResponseModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw mapProductDioException(error);
    } on FormatException {
      throw const ProductMalformedFailure();
    } on TypeError {
      throw const ProductMalformedFailure();
    }
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw const FormatException('Unexpected product response.');
  }
}
