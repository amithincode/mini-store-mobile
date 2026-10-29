import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/config/app_config.dart';
import 'package:mini_store_app/core/network/api_log_interceptor.dart';
import 'package:mini_store_app/core/network/dio_client.dart';

const AppConfig _config = AppConfig(
  apiBaseUrl: 'https://dummyjson.com',
  authLoginPath: '/auth/login',
  authRefreshPath: '/auth/refresh',
  productsPath: '/products',
  productsSearchPath: '/products/search',
  productDetailPath: '/products/{id}',
  categoriesPath: '/products/categories',
  categoryProductsPath: '/products/category/{slug}',
);

void main() {
  test('configures the Dio client without making a request', () {
    final dio = createDioClient(_config);

    expect(dio.options.baseUrl, 'https://dummyjson.com');
    expect(dio.options.connectTimeout, const Duration(seconds: 15));
    expect(dio.options.receiveTimeout, const Duration(seconds: 20));
    expect(dio.options.sendTimeout, const Duration(seconds: 20));
    expect(dio.options.headers['Accept'], 'application/json');
    // Dio installs a single content-type interceptor by default. The app adds
    // the debug API logger here and attaches authentication in DI.
    expect(dio.interceptors, hasLength(2));
    expect(dio.interceptors.whereType<ApiLogInterceptor>(), hasLength(1));
  });

  test('accepts a shared logger so request numbering continues', () {
    final logger = ApiLogInterceptor();
    final first = createDioClient(_config, logInterceptor: logger);
    final second = createDioClient(_config, logInterceptor: logger);

    expect(first.interceptors.contains(logger), isTrue);
    expect(second.interceptors.contains(logger), isTrue);
    expect(first.interceptors, hasLength(2));
    expect(second.interceptors, hasLength(2));
  });
}
