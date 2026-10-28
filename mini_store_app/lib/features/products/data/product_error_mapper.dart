import 'package:dio/dio.dart';

import '../domain/failures/product_failure.dart';

/// Maps transport exceptions to product failures.
///
/// A 401/403 is always an authentication failure, never "offline". Actual
/// transport failures are classified so the UI can show a useful message.
ProductFailure mapProductDioException(DioException exception) {
  final statusCode = exception.response?.statusCode;

  if (statusCode == 401 || statusCode == 403) {
    return const ProductAuthFailure();
  }

  if (statusCode != null && statusCode >= 500) {
    return const ProductServerFailure();
  }

  switch (exception.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return const ProductOfflineFailure();
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const ProductTimeoutFailure();
    case DioExceptionType.badResponse:
      return const ProductUnexpectedFailure();
    case DioExceptionType.cancel:
      return const ProductUnexpectedFailure();
    case DioExceptionType.badCertificate:
      return const ProductServerFailure();
    case DioExceptionType.unknown:
      return _isUnreachable(exception)
          ? const ProductOfflineFailure()
          : const ProductUnexpectedFailure();
  }
}

bool _isUnreachable(DioException exception) {
  if (exception.response != null) {
    return false;
  }

  final message = (exception.message ?? '').toLowerCase();
  if (message.contains('xmlhttprequest') ||
      message.contains('failed to fetch') ||
      message.contains('socketexception') ||
      message.contains('connection refused') ||
      message.contains('network is unreachable') ||
      message.contains('err_internet_disconnected') ||
      message.contains('err_name_not_resolved')) {
    return true;
  }

  return exception.error is Exception;
}
