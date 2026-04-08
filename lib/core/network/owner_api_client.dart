import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../config/owner_api_config.dart';
import '../../features/auth/data/owner_auth_session_store.dart';
import 'secure_cookie_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class OwnerApiClient {
  OwnerApiClient._internal();

  static final OwnerApiClient _instance = OwnerApiClient._internal();
  factory OwnerApiClient() => _instance;

  final OwnerAuthSessionStore _sessionStore = OwnerAuthSessionStore();
  static final PersistCookieJar _cookieJar = PersistCookieJar(
    storage: const SecureCookieStorage(),
  );
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: OwnerApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(CookieManager(_cookieJar));

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
    bool requiresAuth = true,
  }) {
    return _request(
      path,
      method: 'DELETE',
      data: data,
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
      final token = await _sessionStore.getAccessToken();
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
      );
      final body = response.data;
      final data = body?['data'];
      final accessToken = data is Map<String, dynamic>
          ? data['accessToken']
          : null;
      if (accessToken is String && accessToken.isNotEmpty) {
        await _sessionStore.saveAccessToken(accessToken);
        return true;
      }
      return false;
    } catch (_) {
      await _cookieJar.deleteAll();
      await _sessionStore.clearAll();
      return false;
    }
  }

  Future<void> clearCookies() => _cookieJar.deleteAll();

  ApiException _toApiException(DioException error) {
    final responseBody = error.response?.data;
    int? statusCode;
    String message = 'Request failed. Please try again.';

    if (responseBody is Map<String, dynamic>) {
      statusCode = error.response?.statusCode;
      message =
          responseBody['error']?.toString() ??
          responseBody['message']?.toString() ??
          message;
    } else if (error.message != null && error.message!.isNotEmpty) {
      message = error.message!;
    }

    return ApiException(message, statusCode: statusCode);
  }
}
