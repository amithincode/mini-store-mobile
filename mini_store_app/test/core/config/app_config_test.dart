import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/config/app_config.dart';
import 'package:mini_store_app/core/error/app_exception.dart';

void main() {
  group('AppConfig.fromEnvironment', () {
    test('reads a valid absolute HTTPS URL', () {
      final config = AppConfig.fromEnvironment({
        'API_BASE_URL': 'https://dummyjson.com',
      });

      expect(config.apiBaseUrl, 'https://dummyjson.com');
    });

    test('trims whitespace and trailing slashes', () {
      final config = AppConfig.fromEnvironment({
        'API_BASE_URL': '  https://dummyjson.com///  ',
      });

      expect(config.apiBaseUrl, 'https://dummyjson.com');
    });

    test('accepts HTTP URLs with a port', () {
      final config = AppConfig.fromEnvironment({
        'API_BASE_URL': 'http://localhost:8080',
      });

      expect(config.apiBaseUrl, 'http://localhost:8080');
    });

    test('throws when the value is missing', () {
      expect(
        () => AppConfig.fromEnvironment(const <String, String>{}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws when the value is empty', () {
      expect(
        () => AppConfig.fromEnvironment({'API_BASE_URL': '   '}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws for a relative URL', () {
      expect(
        () => AppConfig.fromEnvironment({'API_BASE_URL': 'dummyjson.com'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws for an unsupported scheme', () {
      expect(
        () =>
            AppConfig.fromEnvironment({'API_BASE_URL': 'ftp://dummyjson.com'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws when the host is missing', () {
      expect(
        () => AppConfig.fromEnvironment({'API_BASE_URL': 'https:///path'}),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });
}
