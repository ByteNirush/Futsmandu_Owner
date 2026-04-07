import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../services/secure_storage_service.dart';

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

  static const String _baseUrl = String.fromEnvironment(
    'OWNER_API_BASE_URL',
    defaultValue: 'http://localhost:3002/api/v1/owner',
  );

  final SecureStorageService _secureStorage = SecureStorageService();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(CookieManager(CookieJar()));

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
      final token = await _secureStorage.getToken();
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
      final response = await _dio.post<Map<String, dynamic>>('/auth/refresh');
      final body = response.data;
      final data = body?['data'];
      final accessToken = data is Map<String, dynamic>
          ? data['accessToken']
          : null;
      if (accessToken is String && accessToken.isNotEmpty) {
        await _secureStorage.saveToken(accessToken);
        return true;
      }
      return false;
    } catch (_) {
      await _secureStorage.deleteToken();
      return false;
    }
  }

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
