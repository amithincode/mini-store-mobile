/// Base exception for expected application failures.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when required environment configuration is missing or invalid.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message);
}
