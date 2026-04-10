import 'package:dio/dio.dart';

import 'api_client.dart';

class ErrorHandler {
  const ErrorHandler._();

  static String messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      final response = error.response?.data;
      if (response is Map<String, dynamic>) {
        final nestedData = response['data'];
        if (nestedData is Map<String, dynamic>) {
          final message = nestedData['message']?.toString();
          if (message != null && message.trim().isNotEmpty) {
            return message;
          }
        }

        final errors = response['errors'];
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
            return details.join(', ');
          }
        }

        final message = response['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }

        final errorText = response['error']?.toString();
        if (errorText != null && errorText.trim().isNotEmpty) {
          return errorText;
        }
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '');
  }
}
