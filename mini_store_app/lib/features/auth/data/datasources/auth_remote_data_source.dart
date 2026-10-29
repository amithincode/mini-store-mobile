import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/failures/auth_failure.dart';
import '../auth_error_mapper.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';

/// Remote authentication contract.
abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String username,
    required String password,
  });

  Future<AuthResponseModel> refresh({required String refreshToken});
}

/// Authentication endpoints configured through `.env`.
class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  DioAuthRemoteDataSource(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

  @override
  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        _config.authLoginPath,
        data: LoginRequestModel(
          username: username,
          password: password,
        ).toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );

      return _parse(response.data);
    } on DioException catch (error) {
      throw mapDioException(error, isLogin: true);
    } on FormatException {
      throw const MalformedResponseFailure();
    }
  }

  @override
  Future<AuthResponseModel> refresh({required String refreshToken}) async {
    try {
      final response = await _dio.post<Object?>(
        _config.authRefreshPath,
        data: <String, dynamic>{
          'refreshToken': refreshToken,
          'expiresInMins': 30,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      return _parse(response.data);
    } on DioException catch (error) {
      throw mapDioException(error, isLogin: false);
    } on FormatException {
      throw const MalformedResponseFailure();
    }
  }

  AuthResponseModel _parse(Object? data) {
    if (data is Map<String, dynamic>) {
      return AuthResponseModel.fromJson(data);
    }

    if (data is Map) {
      return AuthResponseModel.fromJson(Map<String, dynamic>.from(data));
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return AuthResponseModel.fromJson(decoded);
      }
    }

    throw const FormatException('Unexpected authentication response.');
  }
}
