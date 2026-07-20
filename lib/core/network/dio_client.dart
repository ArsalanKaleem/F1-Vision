import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/failures.dart';
import 'cache_store.dart';
import 'interceptors.dart';

/// Thin wrapper over [Dio] that wires interceptors, a TTL cache and translates
/// `DioException`s into the app's [AppException] hierarchy. One instance per
/// upstream base URL.
class DioClient {
  DioClient({
    required String baseUrl,
    CacheStore? cache,
    bool enableLogging = true,
  }) : _cache = cache ?? CacheStore() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
          // Identifying yourself is good API citizenship (Jolpica asks for it).
          'User-Agent': 'F1Vision/0.1 (Flutter)',
        },
      ),
    );

    _dio.interceptors.addAll([
      RetryInterceptor(_dio),
      LoggingInterceptor(enabled: enableLogging),
    ]);
  }

  late final Dio _dio;
  final CacheStore _cache;

  /// GET returning decoded JSON. Optionally cached by full URL for [cacheTtl].
  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
    Duration? cacheTtl,
  }) async {
    final cacheKey = _keyFor(path, query);

    if (cacheTtl != null) {
      final cached = _cache.read(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      final data = response.data;
      if (cacheTtl != null && data != null) {
        _cache.write(cacheKey, data as Object, cacheTtl);
      }
      return data;
    } on DioException catch (e) {
      throw _translate(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  String _keyFor(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return path;
    final sorted = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final qs = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?$qs';
  }

  AppException _translate(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 429) return const RateLimitException();
        return ServerException(
          'Upstream returned $code.',
          statusCode: code,
        );
      default:
        return const ServerException('Unexpected network error.');
    }
  }
}
