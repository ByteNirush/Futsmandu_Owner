import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';
import '../domain/owner_auth_models.dart';

class OwnerAuthApi {
  OwnerAuthApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<OwnerRegistrationResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? businessName,
  }) async {
    final result = await _apiClient.post(
      OwnerApiConfig.registerEndpoint,
      requiresAuth: false,
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        if (businessName != null && businessName.trim().isNotEmpty)
          'business_name': businessName.trim(),
      },
    );

    return OwnerRegistrationResult.fromApiJson(result);
  }

  Future<OtpVerificationResult> verifyOtp({
    required String ownerId,
    required String otp,
  }) async {
    final result = await _apiClient.post(
      OwnerApiConfig.verifyOtpEndpoint,
      requiresAuth: false,
      data: {
        'ownerId': ownerId.trim(),
        'otp': otp.trim(),
      },
    );

    return OtpVerificationResult.fromJson(result);
  }

  Future<String> resendOtp({required String ownerId}) async {
    final result = await _apiClient.post(
      OwnerApiConfig.resendOtpEndpoint,
      requiresAuth: false,
      data: {'ownerId': ownerId.trim()},
    );

    final message = result['message']?.toString();
    return message != null && message.trim().isNotEmpty
        ? message
        : 'OTP sent successfully.';
  }

  Future<OwnerLoginResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      OwnerApiConfig.loginEndpoint,
      requiresAuth: false,
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );

    final accessToken = result['accessToken'];
    final owner = result['owner'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        owner is! Map<String, dynamic>) {
      throw ApiException('Invalid login response from server.');
    }

    return OwnerLoginResult(
      accessToken: accessToken,
      owner: Owner.fromApiJson(owner),
    );
  }

  Future<String> refresh() async {
    final result = await _apiClient.post(
      OwnerApiConfig.refreshEndpoint,
      requiresAuth: false,
    );
    final accessToken = result['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw ApiException('Invalid refresh response from server.');
    }
    return accessToken;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(OwnerApiConfig.logoutEndpoint);
    } finally {
      await _apiClient.clearCookies();
    }
  }

  Future<UploadDocUrl> uploadDocs({required String docType}) async {
    final result = await _apiClient.post(
      OwnerApiConfig.uploadDocsEndpoint,
      data: {'docType': docType},
    );
    final uploadUrl = result['uploadUrl'];
    final key = result['key'];
    if (uploadUrl is! String || key is! String) {
      throw ApiException('Invalid upload URL response from server.');
    }
    return UploadDocUrl(uploadUrl: uploadUrl, key: key);
  }
}

class UploadDocUrl {
  UploadDocUrl({required this.uploadUrl, required this.key});

  final String uploadUrl;
  final String key;
}
