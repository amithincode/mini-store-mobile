import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/failures/auth_failure.dart';

/// Maps transport exceptions to failures whose messages can be shown directly.
///
/// Server messages are preferred for authentication errors so responses such as
/// `{"message": "Invalid credentials"}` reach the user unchanged.
AuthFailure mapDioException(DioException exception, {required bool isLogin}) {
  final statusCode = exception.response?.statusCode;
  final serverMessage = _extractMessage(exception.response?.data);

  if (statusCode != null && statusCode >= 500) {
    return ServerFailure(
      serverMessage ?? 'Something went wrong on our side. Please try again.',
    );
  }

  if (isLogin && _isAuthStatus(statusCode)) {
    return InvalidCredentialsFailure(
      serverMessage ?? 'Invalid username or password.',
    );
  }

  if (!isLogin && _isAuthStatus(statusCode)) {
    return UnauthorizedFailure(
      serverMessage ?? 'Your session expired. Please sign in again.',
    );
  }

  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => const NetworkFailure(),
    DioExceptionType.badResponse => UnexpectedFailure(
      serverMessage ?? 'The server returned an unexpected response.',
    ),
    DioExceptionType.cancel => const UnexpectedFailure(
      'The request was cancelled. Please try again.',
    ),
    DioExceptionType.unknown =>
      exception.error is FormatException
          ? const MalformedResponseFailure()
          : const UnexpectedFailure(),
  };
}

bool _isAuthStatus(int? statusCode) {
  return statusCode == 400 || statusCode == 401 || statusCode == 403;
}

String? _extractMessage(Object? data) {
  if (data is Map) {
    final message = data['message'];
    if (message is String) {
      return _sanitize(message);
    }
    return null;
  }

  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty || trimmed.startsWith('<')) {
      return null;
    }

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return _extractMessage(decoded);
        }
      } on FormatException {
        return null;
      }
    }

    return _sanitize(trimmed);
  }

  return null;
}

String? _sanitize(String value) {
  final collapsed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.isEmpty) {
    return null;
  }

  return collapsed.length > 300 ? collapsed.substring(0, 300) : collapsed;
}
