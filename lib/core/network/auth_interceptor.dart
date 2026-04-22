import 'package:dio/dio.dart';
import 'token_manager.dart';
import '../config/owner_api_config.dart';

/// Attaches the Authorization Bearer token ONLY to requests destined for the
/// backend API, and strips all auth/cookie/content-type headers from requests
/// going to external storage services (Cloudflare R2, AWS S3).
///
/// R2 presigned URLs already carry credentials in query params (X-Amz-Signature).
/// Sending a Bearer token alongside them causes R2 to return 400 InvalidArgument.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({TokenManager? tokenManager})
      : _tokenManager = tokenManager ?? TokenManager();

  final TokenManager _tokenManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final backendUri = Uri.tryParse(OwnerApiConfig.baseUrl);
    final requestUri = options.uri;

    final isBackendApi = backendUri != null &&
        (requestUri.host == backendUri.host ||
            requestUri.toString().startsWith(OwnerApiConfig.baseUrl));

    final requiresAuth = options.extra['requiresAuth'] as bool? ?? true;

    if (requiresAuth && isBackendApi && !_isExternalStorage(requestUri)) {
      final token = await _tokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else {
      // Strip every header that external storage services (R2, S3) reject or
      // misinterpret. Content-Type is included because ApiClient's BaseOptions
      // sets it globally and R2 presigned GETs must not receive it.
      options.headers.remove('Authorization');
      options.headers.remove('authorization');
      options.headers.remove('Cookie');
      options.headers.remove('cookie');
      if (!isBackendApi) {
        options.headers.remove('Content-Type');
        options.headers.remove('content-type');
      }
    }

    return super.onRequest(options, handler);
  }

  /// Returns true for any Cloudflare R2 or AWS S3 hostname variant.
  static bool _isExternalStorage(Uri uri) {
    if (uri.host.contains('r2.cloudflarestorage.com')) return true;
    if (uri.host.contains('r2.dev')) return true;
    if (uri.host.contains('amazonaws.com')) return true;
    return false;
  }
}
