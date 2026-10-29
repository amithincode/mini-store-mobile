import '../error/app_exception.dart';

/// Runtime configuration loaded from `.env`.
///
/// Every API endpoint lives here so a path can be changed without touching
/// code. Values are validated during startup and fail fast with a readable
/// [ConfigurationException].
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.authLoginPath,
    required this.authRefreshPath,
    required this.productsPath,
    required this.productsSearchPath,
    required this.productDetailPath,
    required this.categoriesPath,
    required this.categoryProductsPath,
  });

  /// Validated base URL for the API client.
  final String apiBaseUrl;

  final String authLoginPath;
  final String authRefreshPath;
  final String productsPath;
  final String productsSearchPath;

  /// Detail path containing the `{id}` placeholder.
  final String productDetailPath;

  final String categoriesPath;

  /// Category products path containing the `{slug}` placeholder.
  final String categoryProductsPath;

  /// Resolves [productDetailPath] for [id].
  String productDetailPathFor(int id) {
    return productDetailPath.replaceAll('{id}', id.toString());
  }

  /// Resolves [categoryProductsPath] for [slug].
  String categoryProductsPathFor(String slug) {
    return categoryProductsPath.replaceAll('{slug}', Uri.encodeComponent(slug));
  }

  factory AppConfig.fromEnvironment(Map<String, String> environment) {
    final rawValue = environment['API_BASE_URL']?.trim();

    if (rawValue == null || rawValue.isEmpty) {
      throw const ConfigurationException(
        'API_BASE_URL is missing. Create a .env file in the project root '
        'and set API_BASE_URL before starting the app.',
      );
    }

    final uri = Uri.tryParse(rawValue);
    final isValidUrl =
        uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isValidUrl) {
      throw ConfigurationException(
        'API_BASE_URL must be an absolute http or https URL. '
        'Received: "$rawValue".',
      );
    }

    var normalizedUrl = rawValue;
    while (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    return AppConfig(
      apiBaseUrl: normalizedUrl,
      authLoginPath: _requirePath(environment, 'API_AUTH_LOGIN_PATH'),
      authRefreshPath: _requirePath(environment, 'API_AUTH_REFRESH_PATH'),
      productsPath: _requirePath(environment, 'API_PRODUCTS_PATH'),
      productsSearchPath: _requirePath(environment, 'API_PRODUCTS_SEARCH_PATH'),
      productDetailPath: _requirePath(
        environment,
        'API_PRODUCTS_DETAIL_PATH',
        requiredPlaceholder: '{id}',
      ),
      categoriesPath: _requirePath(environment, 'API_CATEGORIES_PATH'),
      categoryProductsPath: _requirePath(
        environment,
        'API_CATEGORY_PRODUCTS_PATH',
        requiredPlaceholder: '{slug}',
      ),
    );
  }

  static String _requirePath(
    Map<String, String> environment,
    String key, {
    String? requiredPlaceholder,
  }) {
    final rawValue = environment[key]?.trim();

    if (rawValue == null || rawValue.isEmpty) {
      throw ConfigurationException(
        '$key is missing. Add $key to the .env file before starting the app.',
      );
    }

    if (!rawValue.startsWith('/') ||
        rawValue.startsWith('//') ||
        rawValue.contains(' ')) {
      throw ConfigurationException(
        '$key must be an API path starting with a single "/". '
        'Received: "$rawValue".',
      );
    }

    if (requiredPlaceholder != null &&
        !rawValue.contains(requiredPlaceholder)) {
      throw ConfigurationException(
        '$key must contain the $requiredPlaceholder placeholder. '
        'Received: "$rawValue".',
      );
    }

    return rawValue;
  }
}
