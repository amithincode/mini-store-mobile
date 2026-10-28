import '../error/app_exception.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  /// Validated base URL for the future API client.
  final String apiBaseUrl;

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

    return AppConfig(apiBaseUrl: normalizedUrl);
  }
}
