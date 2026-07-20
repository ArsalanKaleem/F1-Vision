import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Pretty, compact request/response logging. Disabled in release via [enabled].
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.enabled = true});
  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      developer.log('→ ${options.method} ${options.uri}', name: 'F1Vision.net');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.uri}',
        name: 'F1Vision.net',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '✗ ${err.response?.statusCode ?? '-'} ${err.requestOptions.uri} '
        '(${err.type.name})',
        name: 'F1Vision.net',
        error: err.message,
      );
    }
    handler.next(err);
  }
}

/// Retries transient failures (timeouts, connection drops, 5xx, 429) using
/// exponential backoff. 429 responses honour the upstream `Retry-After` header
/// when present — important for Jolpica's strict hourly limit.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);
  final Dio _dio;

  static const _retryKey = '__retry_count';

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final code = err.response?.statusCode ?? 0;
    return code == 429 || (code >= 500 && code < 600);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_retryKey] as int?) ?? 0;

    if (!_isRetryable(err) || attempt >= ApiConstants.maxRetries) {
      return handler.next(err);
    }

    final delay = _backoffFor(err, attempt);
    await Future<void>.delayed(delay);

    final options = err.requestOptions
      ..extra[_retryKey] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Duration _backoffFor(DioException err, int attempt) {
    // Respect Retry-After (seconds) on 429 if provided.
    final retryAfter = err.response?.headers.value('retry-after');
    final parsed = int.tryParse(retryAfter ?? '');
    if (parsed != null) return Duration(seconds: parsed);

    // Otherwise exponential: base * 2^attempt.
    final ms = ApiConstants.retryBaseDelay.inMilliseconds * (1 << attempt);
    return Duration(milliseconds: ms);
  }
}
