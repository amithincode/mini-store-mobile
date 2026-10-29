import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/config/app_config.dart';
import 'package:mini_store_app/core/error/app_exception.dart';

/// Every endpoint key `AppConfig.fromEnvironment` now requires.
const Map<String, String> _requiredPaths = <String, String>{
  'API_AUTH_LOGIN_PATH': '/auth/login',
  'API_AUTH_REFRESH_PATH': '/auth/refresh',
  'API_PRODUCTS_PATH': '/products',
  'API_PRODUCTS_SEARCH_PATH': '/products/search',
  'API_PRODUCTS_DETAIL_PATH': '/products/{id}',
  'API_CATEGORIES_PATH': '/products/categories',
  'API_CATEGORY_PRODUCTS_PATH': '/products/category/{slug}',
};

Map<String, String> _environment([Map<String, String> overrides = const {}]) {
  return <String, String>{..._requiredPaths, ...overrides};
}

void main() {
  group('AppConfig.fromEnvironment', () {
    test('reads a valid absolute HTTPS URL', () {
      final config = AppConfig.fromEnvironment(
        _environment({'API_BASE_URL': 'https://dummyjson.com'}),
      );

      expect(config.apiBaseUrl, 'https://dummyjson.com');
    });

    test('trims whitespace and trailing slashes', () {
      final config = AppConfig.fromEnvironment(
        _environment({'API_BASE_URL': '  https://dummyjson.com///  '}),
      );

      expect(config.apiBaseUrl, 'https://dummyjson.com');
    });

    test('accepts HTTP URLs with a port', () {
      final config = AppConfig.fromEnvironment(
        _environment({'API_BASE_URL': 'http://localhost:8080'}),
      );

      expect(config.apiBaseUrl, 'http://localhost:8080');
    });

    test('reads every endpoint path from the environment', () {
      final config = AppConfig.fromEnvironment(
        _environment({'API_BASE_URL': 'https://dummyjson.com'}),
      );

      expect(config.authLoginPath, '/auth/login');
      expect(config.authRefreshPath, '/auth/refresh');
      expect(config.productsPath, '/products');
      expect(config.productsSearchPath, '/products/search');
      expect(config.productDetailPathFor(7), '/products/7');
      expect(config.categoriesPath, '/products/categories');
      expect(
        config.categoryProductsPathFor('mens shirts'),
        '/products/category/mens%20shirts',
      );
    });

    test('throws when the value is missing', () {
      expect(
        () => AppConfig.fromEnvironment(const <String, String>{}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws when the value is empty', () {
      expect(
        () => AppConfig.fromEnvironment(_environment({'API_BASE_URL': '   '})),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws for a relative URL', () {
      expect(
        () => AppConfig.fromEnvironment(
          _environment({'API_BASE_URL': 'dummyjson.com'}),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws for an unsupported scheme', () {
      expect(
        () => AppConfig.fromEnvironment(
          _environment({'API_BASE_URL': 'ftp://dummyjson.com'}),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws when the host is missing', () {
      expect(
        () => AppConfig.fromEnvironment(
          _environment({'API_BASE_URL': 'https:///path'}),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws when a required endpoint path is missing', () {
      final environment = _environment({
        'API_BASE_URL': 'https://dummyjson.com',
      })..remove('API_PRODUCTS_PATH');

      expect(
        () => AppConfig.fromEnvironment(environment),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws when a placeholder is missing', () {
      expect(
        () => AppConfig.fromEnvironment(
          _environment({
            'API_BASE_URL': 'https://dummyjson.com',
            'API_PRODUCTS_DETAIL_PATH': '/products',
          }),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });
}
