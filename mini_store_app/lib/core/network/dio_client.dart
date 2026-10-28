import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Builds the future API client.
///
/// Phase 1 intentionally configures transport only: no requests are made and
/// no authentication headers or interceptors are installed.
Dio createDioClient(AppConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );
}
