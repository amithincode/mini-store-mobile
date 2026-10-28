import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_log_interceptor.dart';

/// Builds the Dio client used for authentication and protected requests.
///
/// Transport and debug API logging are configured here. Authentication headers
/// and refresh handling are attached as interceptors in dependency injection.
///
/// Pass the same [logInterceptor] when building more than one client so request
/// numbers continue across them.
Dio createDioClient(AppConfig config, {ApiLogInterceptor? logInterceptor}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(logInterceptor ?? ApiLogInterceptor());

  return dio;
}
