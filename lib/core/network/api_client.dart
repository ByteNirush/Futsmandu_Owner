import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../config/owner_api_config.dart';
import 'debug_dio_logging_interceptor.dart';
import 'secure_cookie_storage.dart';
import 'token_manager.dart';
import 'auth_interceptor.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    TokenManager? tokenManager,
    PersistCookieJar? cookieJar,
    Dio? dio,
  })  : _tokenManager = tokenManager ?? TokenManager(),
        _cookieJar =
            cookieJar ??
            PersistCookieJar(storage: const SecureCookieStorage()),
        _dio =
            dio ??
            Dio(
              BaseOptions(
                baseUrl: OwnerApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                headers: const {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(AuthInterceptor(tokenManager: _tokenManager));
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(DebugDioLoggingInterceptor());
  }

  final TokenManager _tokenManager;
  final PersistCookieJar _cookieJar;
  final Dio _dio;
  
  // Prevent concurrent refresh requests
  Completer<bool>? _refreshCompleter;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    bool requiresAuth = true,
  }) {
    return _request(
      path,
      method: 'POST',
      data: data,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    bool requiresAuth = true,
  }) {
    return _request(
      path,
      method: 'PUT',
      data: data,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    required bool requiresAuth,
    bool hasRetried = false,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          extra: {'requiresAuth': requiresAuth}, // Pass requiresAuth so interceptor knows
        ),
      );

      final body = response.data;
      if (body == null) {
        throw ApiException(
          'Empty response from server',
          statusCode: response.statusCode,
        );
      }

      final wrappedData = body['data'];
      if (wrappedData is Map<String, dynamic>) {
        return wrappedData;
      }
      if (wrappedData is List<dynamic>) {
        return <String, dynamic>{
          'data': wrappedData,
          'items': wrappedData,
        };
      }
      return <String, dynamic>{'value': wrappedData};
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 && requiresAuth && !hasRetried) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _request(
            path,
            method: method,
            data: data,
            queryParameters: queryParameters,
            requiresAuth: requiresAuth,
            hasRetried: true,
          );
        }
      }
      throw _toApiException(error);
    }
  }

  Future<bool> _tryRefreshToken() async {
    // Prevent concurrent refresh requests
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        OwnerApiConfig.refreshEndpoint,
        // Don't override headers to allow CookieManager to include cookies automatically
        options: Options(
          headers: const {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final statusCode = response.statusCode;
      if (statusCode == 200 || statusCode == 201) {
        final body = response.data;
        final data = body?['data'];
        final accessToken = data is Map<String, dynamic>
            ? data['accessToken']
            : null;

        if (accessToken is String && accessToken.isNotEmpty) {
          await _tokenManager.saveAccessToken(accessToken);
          
          // Also save refresh token if present in response
          final refreshToken = data is Map<String, dynamic>
              ? data['refreshToken']
              : null;
          if (refreshToken is String && refreshToken.isNotEmpty) {
            await _tokenManager.saveRefreshToken(refreshToken);
          }

          _refreshCompleter?.complete(true);
          return true;
        }
      }

      // If refresh failed due to auth issues, clear session
      if (statusCode == 401 || statusCode == 403) {
        await clearSession();
      }

      _refreshCompleter?.complete(false);
      return false;
    } catch (error) {
      // If it's a network error or other issue, still clear session on auth errors
      if (error is DioException) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          await clearSession();
        }
      }
      _refreshCompleter?.completeError(error);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> clearCookies() => _cookieJar.deleteAll();

  Future<void> clearSession() async {
    await Future.wait([
      clearCookies(),
      _tokenManager.clearAll(),
    ]);
  }

  ApiException _toApiException(DioException error) {
    final responseBody = error.response?.data;
    int? statusCode;
    String message = 'Request failed. Please try again.';

    if (responseBody is Map<String, dynamic>) {
      statusCode = error.response?.statusCode;
      final errors = responseBody['errors'];
      if (errors is List && errors.isNotEmpty) {
        final details = errors
            .map((entry) {
              if (entry is Map<String, dynamic>) {
                return entry['message']?.toString();
              }
              return entry?.toString();
            })
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (details.isNotEmpty) {
          message = details.join(', ');
        }
      }

      final responseMessage = responseBody['message'];
      String? normalizedResponseMessage;
      if (responseMessage is String && responseMessage.trim().isNotEmpty) {
        normalizedResponseMessage = responseMessage.trim();
      } else if (responseMessage is List) {
        final details = responseMessage
            .map((entry) => entry?.toString())
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (details.isNotEmpty) {
          normalizedResponseMessage = details.join(', ');
        }
      }

      message = message != 'Request failed. Please try again.'
          ? message
          : normalizedResponseMessage ??
              responseBody['error']?.toString() ??
              message;
    } else if (error.message != null && error.message!.isNotEmpty) {
      message = error.message!;
    }

    // Clean up the message: strip ANSI codes and truncate if too long
    message = _sanitizeErrorMessage(message);

    return ApiException(message, statusCode: statusCode);
  }

  /// Strips ANSI escape codes and sanitizes verbose backend error messages
  String _sanitizeErrorMessage(String message) {
    // Strip ANSI escape codes (e.g., \u001b[31m, \u001b[39m, etc.)
    final ansiRegex = RegExp(r'\x1B\[[0-9;]*m');
    var clean = message.replaceAll(ansiRegex, '');

    // If message contains internal file paths or stack traces (indicated by
    // common patterns), return a generic user-friendly message
    if (clean.contains('/Users/') ||
        clean.contains('prisma.') ||
        clean.contains('invocation in') ||
        clean.contains('Promise.') ||
        clean.contains('await') && clean.contains('const')) {
      return 'Server error. Please try again later.';
    }

    // Truncate if too long (max 200 chars)
    if (clean.length > 200) {
      clean = '${clean.substring(0, 197)}...';
    }

    return clean.trim();
  }
}
