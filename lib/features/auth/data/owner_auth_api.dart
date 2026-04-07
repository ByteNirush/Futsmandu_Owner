import '../../../core/network/owner_api_client.dart';
import '../../../core/services/secure_storage_service.dart';

class OwnerAuthApi {
  OwnerAuthApi({OwnerApiClient? apiClient, SecureStorageService? secureStorage})
    : _apiClient = apiClient ?? OwnerApiClient(),
      _secureStorage = secureStorage ?? SecureStorageService();

  final OwnerApiClient _apiClient;
  final SecureStorageService _secureStorage;

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? businessName,
  }) async {
    await _apiClient.post(
      '/auth/register',
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
  }

  Future<OwnerLoginResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/login',
      requiresAuth: false,
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );

    final accessToken = result['accessToken'];
    final owner = result['owner'];
    if (accessToken is! String || owner is! Map<String, dynamic>) {
      throw ApiException('Invalid login response from server.');
    }

    await _secureStorage.saveToken(accessToken);

    return OwnerLoginResult(
      accessToken: accessToken,
      ownerId: owner['id']?.toString() ?? '',
      ownerName: owner['name']?.toString() ?? '',
      ownerEmail: owner['email']?.toString() ?? '',
    );
  }

  Future<String> refresh() async {
    final result = await _apiClient.post('/auth/refresh', requiresAuth: false);
    final accessToken = result['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw ApiException('Invalid refresh response from server.');
    }
    await _secureStorage.saveToken(accessToken);
    return accessToken;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } finally {
      await _secureStorage.deleteToken();
    }
  }

  Future<UploadDocUrl> uploadDocs({required String docType}) async {
    final result = await _apiClient.post(
      '/auth/upload-docs',
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

class OwnerLoginResult {
  OwnerLoginResult({
    required this.accessToken,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
  });

  final String accessToken;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
}

class UploadDocUrl {
  UploadDocUrl({required this.uploadUrl, required this.key});

  final String uploadUrl;
  final String key;
}
