import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCookieStorage implements Storage {
  const SecureCookieStorage();

  static const String _prefix = 'owner_cookie_';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  String _key(String key) => '$_prefix$key';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) {
    return _storage.read(key: _key(key));
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: _key(key), value: value);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: _key(key));
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: _key(key));
    }
  }
}
