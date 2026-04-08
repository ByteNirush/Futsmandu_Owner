import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/secure_storage_service.dart';
import '../domain/owner_auth_models.dart';

class OwnerAuthSessionStore {
  OwnerAuthSessionStore({
    SecureStorageService? secureStorage,
    SharedPreferences? sharedPreferences,
  }) : _secureStorage = secureStorage ?? SecureStorageService(),
       _sharedPreferences = sharedPreferences;

  static const String _ownerProfileKey = 'owner_auth_profile';

  final SecureStorageService _secureStorage;
  final SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> _prefs() async {
    return _sharedPreferences ?? SharedPreferences.getInstance();
  }

  Future<void> saveAccessToken(String token) => _secureStorage.saveToken(token);

  Future<String?> getAccessToken() => _secureStorage.getToken();

  Future<void> deleteAccessToken() => _secureStorage.deleteToken();

  Future<void> saveOwner(OwnerAuthProfile owner) async {
    final prefs = await _prefs();
    await prefs.setString(_ownerProfileKey, jsonEncode(owner.toStorageJson()));
  }

  Future<OwnerAuthProfile?> getOwner() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_ownerProfileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return OwnerAuthProfile.fromStorageJson(decoded);
  }

  Future<void> deleteOwner() async {
    final prefs = await _prefs();
    await prefs.remove(_ownerProfileKey);
  }

  Future<void> clearAll() async {
    await Future.wait([deleteAccessToken(), deleteOwner()]);
  }
}
