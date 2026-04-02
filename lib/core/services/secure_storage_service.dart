import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service to handle encrypted storage securely across multiple platforms.
/// 
/// Example Usage:
/// ```dart
/// final secureStorage = SecureStorageService();
/// 
/// // Save token after login
/// await secureStorage.saveToken('my_secure_jwt_token_here');
/// 
/// // Retrieve token on app start
/// final token = await secureStorage.getToken();
/// if (token != null) {
///   // proceed to login
/// }
/// 
/// // Delete token on logout
/// await secureStorage.deleteToken();
/// // or clear all user specific data
/// await secureStorage.clearAll();
/// ```
class SecureStorageService {
  // Singleton pattern to ensure only one instance of the service is used.
  SecureStorageService._internal();
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  // Constants for storage keys to avoid hardcoded strings
  static const String _tokenKey = 'auth_token';

  // The instance of flutter_secure_storage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Platform-specific options for Android
  AndroidOptions _getAndroidOptions() => const AndroidOptions();

  // Platform-specific options for iOS
  // accessibility sets when the keychain item can be read.
  // first_unlock means the item is only accessible after the device has been unlocked 
  // at least once since reboot.
  IOSOptions _getIOSOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      );

  /// Saves the authentication token securely.
  /// 
  /// [token] The string token to store.
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(
        key: _tokenKey,
        value: token,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      // In a real app, you might want to log this using a logging service
      throw Exception('Failed to save secure token: $e');
    }
  }

  /// Retrieves the authentication token.
  /// 
  /// Returns the token if it exists, otherwise [null].
  Future<String?> getToken() async {
    try {
      return await _storage.read(
        key: _tokenKey,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw Exception('Failed to retrieve secure token: $e');
    }
  }

  /// Deletes the authentication token.
  /// 
  /// Use this when logging out specifically for the token.
  Future<void> deleteToken() async {
    try {
      await _storage.delete(
        key: _tokenKey,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw Exception('Failed to delete secure token: $e');
    }
  }

  /// Clears all securely stored data.
  /// 
  /// Best practice is to call this during logout to ensure no sensitive 
  /// data is left behind.
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll(
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw Exception('Failed to clear secure storage: $e');
    }
  }
}
