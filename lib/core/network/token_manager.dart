import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  TokenManager._internal();

  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;

  static const String _accessTokenKey = 'owner_access_token';
  static const String _refreshTokenKey = 'owner_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AndroidOptions _androidOptions() => const AndroidOptions();

  IOSOptions _iosOptions() => const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  Future<void> saveAccessToken(String token) {
    return _storage.write(
      key: _accessTokenKey,
      value: token,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<String?> getAccessToken() {
    return _storage.read(
      key: _accessTokenKey,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<void> deleteAccessToken() {
    return _storage.delete(
      key: _accessTokenKey,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(
      key: _refreshTokenKey,
      value: token,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<String?> getRefreshToken() {
    return _storage.read(
      key: _refreshTokenKey,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<void> deleteRefreshToken() {
    return _storage.delete(
      key: _refreshTokenKey,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }
}
