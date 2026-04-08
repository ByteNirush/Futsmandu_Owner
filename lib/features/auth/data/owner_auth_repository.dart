import '../domain/owner_auth_models.dart';
import 'owner_auth_api.dart';
import 'owner_auth_session_store.dart';

class OwnerAuthRepository {
  OwnerAuthRepository({
    OwnerAuthApi? remoteDataSource,
    OwnerAuthSessionStore? sessionStore,
  }) : _remoteDataSource = remoteDataSource ?? OwnerAuthApi(),
       _sessionStore = sessionStore ?? OwnerAuthSessionStore();

  final OwnerAuthApi _remoteDataSource;
  final OwnerAuthSessionStore _sessionStore;

  Future<OwnerRegistrationResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? businessName,
  }) {
    return _remoteDataSource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      businessName: businessName,
    );
  }

  Future<OwnerAuthProfile> login({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _sessionStore.saveAccessToken(result.accessToken);
    await _sessionStore.saveOwner(result.owner);
    return result.owner;
  }

  Future<void> refreshAccessToken() async {
    final accessToken = await _remoteDataSource.refresh();
    await _sessionStore.saveAccessToken(accessToken);
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _sessionStore.clearAll();
    }
  }

  Future<OwnerAuthProfile?> restoreSession() async {
    final owner = await _sessionStore.getOwner();
    if (owner == null) {
      return null;
    }

    try {
      await refreshAccessToken();
      return owner;
    } catch (_) {
      await _sessionStore.clearAll();
      return null;
    }
  }

  Future<void> clearSession() => _sessionStore.clearAll();
}
