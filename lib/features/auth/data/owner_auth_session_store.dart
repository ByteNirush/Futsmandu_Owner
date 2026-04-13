import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/token_manager.dart';
import '../domain/owner_auth_models.dart';

class OwnerAuthSessionStore {
  OwnerAuthSessionStore({
    SharedPreferences? sharedPreferences,
    TokenManager? tokenManager,
  }) : _tokenManager = tokenManager ?? TokenManager(),
       _sharedPreferences = sharedPreferences;

  static const String _ownerProfileKey = 'owner_auth_profile';
  static const String _ownerKycDocCacheKey = 'owner_kyc_docs_cache_v1';

  final TokenManager _tokenManager;
  final SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> _prefs() async {
    return _sharedPreferences ?? SharedPreferences.getInstance();
  }

  Future<void> saveAccessToken(String token) => _tokenManager.saveAccessToken(token);

  Future<String?> getAccessToken() => _tokenManager.getAccessToken();

  Future<void> deleteAccessToken() => _tokenManager.deleteAccessToken();

  Future<void> saveRefreshToken(String token) => _tokenManager.saveRefreshToken(token);

  Future<String?> getRefreshToken() => _tokenManager.getRefreshToken();

  Future<void> deleteRefreshToken() => _tokenManager.deleteRefreshToken();

  Future<void> saveOwner(Owner owner) async {
    final prefs = await _prefs();
    await prefs.setString(_ownerProfileKey, jsonEncode(owner.toStorageJson()));
  }

  Future<Owner?> getOwner() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_ownerProfileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return Owner.fromStorageJson(decoded);
  }

  Future<String?> getOwnerRole() async {
    final owner = await getOwner();
    return owner?.role;
  }

  Future<void> deleteOwner() async {
    final prefs = await _prefs();
    await prefs.remove(_ownerProfileKey);
  }

  Future<Map<String, String>> getKycDocKeysForOwner(String ownerId) async {
    final normalizedOwnerId = ownerId.trim();
    if (normalizedOwnerId.isEmpty) {
      return const <String, String>{};
    }

    final cache = await _readKycDocCache();
    final ownerDocsRaw = cache[normalizedOwnerId];
    if (ownerDocsRaw is! Map<String, dynamic>) {
      return const <String, String>{};
    }

    final parsed = <String, String>{};
    for (final entry in ownerDocsRaw.entries) {
      final key = entry.key.trim();
      final value = entry.value?.toString().trim();
      if (key.isNotEmpty && value != null && value.isNotEmpty) {
        parsed[key] = value;
      }
    }

    return parsed;
  }

  Future<void> saveKycDocKeyForOwner({
    required String ownerId,
    required String docType,
    required String storageKey,
  }) async {
    final normalizedOwnerId = ownerId.trim();
    final normalizedDocType = docType.trim();
    final normalizedStorageKey = storageKey.trim();

    if (normalizedOwnerId.isEmpty ||
        normalizedDocType.isEmpty ||
        normalizedStorageKey.isEmpty) {
      return;
    }

    final cache = await _readKycDocCache();
    final ownerDocs =
        (cache[normalizedOwnerId] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(cache[normalizedOwnerId] as Map<String, dynamic>)
        : <String, dynamic>{};

    ownerDocs[normalizedDocType] = normalizedStorageKey;
    cache[normalizedOwnerId] = ownerDocs;
    await _writeKycDocCache(cache);
  }

  Future<void> saveKycDocKeysForOwner({
    required String ownerId,
    required Map<String, String> keys,
  }) async {
    final normalizedOwnerId = ownerId.trim();
    if (normalizedOwnerId.isEmpty || keys.isEmpty) {
      return;
    }

    final cache = await _readKycDocCache();
    final ownerDocs =
        (cache[normalizedOwnerId] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(cache[normalizedOwnerId] as Map<String, dynamic>)
        : <String, dynamic>{};

    for (final entry in keys.entries) {
      final docType = entry.key.trim();
      final storageKey = entry.value.trim();
      if (docType.isEmpty || storageKey.isEmpty) {
        continue;
      }
      ownerDocs[docType] = storageKey;
    }

    cache[normalizedOwnerId] = ownerDocs;
    await _writeKycDocCache(cache);
  }

  Future<Map<String, dynamic>> _readKycDocCache() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_ownerKycDocCacheKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }

  Future<void> _writeKycDocCache(Map<String, dynamic> cache) async {
    final prefs = await _prefs();
    await prefs.setString(_ownerKycDocCacheKey, jsonEncode(cache));
  }

  Future<void> clearAll() async {
    await Future.wait([deleteAccessToken(), deleteOwner()]);
  }
}
