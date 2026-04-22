import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DebugDioLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--- DIO REQUEST ---');
      debugPrint('Method: ${options.method}');
      debugPrint('URL: ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      debugPrint('Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--- DIO RESPONSE ---');
      debugPrint('Method: ${response.requestOptions.method}');
      debugPrint('URL: ${response.requestOptions.uri}');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--- DIO ERROR ---');
      debugPrint('Method: ${err.requestOptions.method}');
      debugPrint('URL: ${err.requestOptions.uri}');
      debugPrint('Headers: ${err.requestOptions.headers}');
      debugPrint('Body: ${err.requestOptions.data}');
      debugPrint('Status: ${err.response?.statusCode}');
      debugPrint('Response: ${err.response?.data}');
      debugPrint('Error: ${err.message}');
    }
    handler.next(err);
  }
}
