import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../config/owner_api_config.dart';
import 'secure_cookie_storage.dart';
import 'token_manager.dart';

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
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  final TokenManager _tokenManager;
  final PersistCookieJar _cookieJar;
  final Dio _dio;

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
    final headers = <String, dynamic>{};
    if (requiresAuth) {
      final token = await _tokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: headers),
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
        return <String, dynamic>{'items': wrappedData};
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        OwnerApiConfig.refreshEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = response.data;
      final data = body?['data'];
      final accessToken = data is Map<String, dynamic>
          ? data['accessToken']
          : null;
      if (accessToken is String && accessToken.isNotEmpty) {
        await _tokenManager.saveAccessToken(accessToken);
        return true;
      }
      return false;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await clearSession();
      }
      return false;
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

    return ApiException(message, statusCode: statusCode);
  }
}
