import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints API traffic as formatted JSON blocks with credentials redacted.
///
/// It is enabled in debug builds only. Headers are never printed, and sensitive
/// body fields are replaced before logging so tokens and passwords stay out of
/// the console.
class ApiLogInterceptor extends Interceptor {
  ApiLogInterceptor({
    bool enabled = kDebugMode,
    void Function(String message)? logger,
    int maxBodyLength = 8000,
  }) : _enabled = enabled,
       _logger = logger ?? debugPrint,
       _maxBodyLength = maxBodyLength;

  static const String _idKey = 'mini_store.api_request_id';
  static const String _startedAtKey = 'mini_store.api_request_started_at';
  static const int _frameWidth = 72;
  static const Set<String> _sensitiveKeys = <String>{
    'password',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'token',
    'authorization',
  };

  final bool _enabled;
  final void Function(String message) _logger;
  final int _maxBodyLength;
  int _nextId = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      final id = ++_nextId;
      options.extra[_idKey] = id;
      options.extra[_startedAtKey] = DateTime.now();

      _logger(
        _frame('API REQUEST #$id', <String>[
          '${options.method} ${options.uri}',
          ..._bodyLines('Request body', options.data),
        ]),
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_enabled) {
      final request = response.requestOptions;
      final id = request.extra[_idKey];
      final label = id == null ? 'API RESPONSE' : 'API RESPONSE #$id';

      _logger(
        _frame('$label · ${response.statusCode ?? 'unknown'}', <String>[
          '${request.method} ${request.uri}',
          'Time: ${_elapsedMs(request)} ms',
          ..._bodyLines('Response body', response.data),
        ]),
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      final request = err.requestOptions;
      final id = request.extra[_idKey];
      final label = id == null ? 'API ERROR' : 'API ERROR #$id';
      final status = err.response?.statusCode?.toString() ?? err.type.name;

      _logger(
        _frame('$label · $status', <String>[
          '${request.method} ${request.uri}',
          'Time: ${_elapsedMs(request)} ms',
          if (err.response == null) 'Error: ${err.message ?? err.type.name}',
          ..._bodyLines('Error body', err.response?.data),
        ]),
      );
    }

    handler.next(err);
  }

  int _elapsedMs(RequestOptions request) {
    final startedAt = request.extra[_startedAtKey];
    if (startedAt is! DateTime) {
      return 0;
    }

    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  List<String> _bodyLines(String title, Object? data) {
    final body = _prettyBody(data);
    if (body == null) {
      return const <String>[];
    }

    return <String>['', title, ...body.split('\n')];
  }

  String? _prettyBody(Object? data) {
    if (data == null) {
      return null;
    }

    if (data is FormData) {
      return '[multipart body: ${data.files.length} files, '
          '${data.fields.length} fields]';
    }

    final decoded = data is String ? (_tryDecodeJson(data) ?? data) : data;

    try {
      final pretty = const JsonEncoder.withIndent(
        '  ',
      ).convert(_redact(decoded));

      if (pretty.length > _maxBodyLength) {
        return '[Body omitted: ${pretty.length} characters exceeds the '
            '$_maxBodyLength-character log limit]';
      }

      return pretty;
    } catch (_) {
      return '[unprintable body]';
    }
  }

  Object? _redact(Object? value) {
    if (value is Map) {
      return value.map<Object?, Object?>((key, entry) {
        final isSensitive =
            key is String && _sensitiveKeys.contains(key.toLowerCase());
        return MapEntry<Object?, Object?>(
          key,
          isSensitive ? '[REDACTED]' : _redact(entry),
        );
      });
    }

    if (value is Iterable) {
      return value.map<Object?>(_redact).toList(growable: false);
    }

    return value;
  }

  Object? _tryDecodeJson(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return null;
    }

    try {
      return jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
  }

  String _frame(String title, List<String> lines) {
    final header = '┌─ $title ';
    final top = header.length < _frameWidth
        ? '$header${'─' * (_frameWidth - header.length)}'
        : header.trimRight();
    final bottom = '└${'─' * _frameWidth}';
    final body = lines.map((line) => line.isEmpty ? '│' : '│ $line').join('\n');

    return '$top\n$body\n$bottom';
  }
}
