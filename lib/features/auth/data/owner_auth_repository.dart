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

  Future<OtpVerificationResult> verifyOtp({
    required String ownerId,
    required String otp,
  }) async {
    return _remoteDataSource.verifyOtp(ownerId: ownerId, otp: otp);
  }

  Future<String> resendOtp({required String ownerId}) {
    return _remoteDataSource.resendOtp(ownerId: ownerId);
  }

  Future<Owner> login({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    final hydratedOwner = await _hydrateOwnerWithLocalKyc(result.owner);

    await _sessionStore.saveAccessToken(result.accessToken);
    
    // Save refresh token if available
    if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
      await _sessionStore.saveRefreshToken(result.refreshToken!);
    }
    
    await _sessionStore.saveOwner(hydratedOwner);
    return hydratedOwner;
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

  Future<Owner?> restoreSession() async {
    final accessToken = await _sessionStore.getAccessToken();
    final rawOwner = await _sessionStore.getOwner();
    final owner = rawOwner == null
        ? null
        : await _hydrateOwnerWithLocalKyc(rawOwner);
    if (owner == null) {
      return null;
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      return owner;
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

  Future<Owner> _hydrateOwnerWithLocalKyc(Owner owner) async {
    final cachedDocKeys = await _sessionStore.getKycDocKeysForOwner(owner.id);
    final cachedAvatar = await _sessionStore.getAvatarForOwner(owner.id);

    var hydrated = owner;

    // Hydrate KYC
    if (owner.kycDocumentKeys.isNotEmpty) {
      await _sessionStore.saveKycDocKeysForOwner(
        ownerId: owner.id,
        keys: owner.kycDocumentKeys,
      );
    } else if (cachedDocKeys.isNotEmpty && !owner.isKycApproved) {
      hydrated = hydrated.copyWith(
        isKycApproved: false,
        kycStatus: KycVerificationStatus.pending,
        kycRejectionReason: null,
        kycDocumentKeys: cachedDocKeys,
      );
    }

    // Hydrate Avatar
    if (owner.avatarAssetId != null && owner.avatarAssetId!.isNotEmpty) {
      await _sessionStore.saveAvatarForOwner(
        ownerId: owner.id,
        assetId: owner.avatarAssetId,
        url: owner.avatarUrl,
      );
    } else if (cachedAvatar != null) {
      hydrated = hydrated.copyWith(
        avatarAssetId: cachedAvatar['assetId'],
        avatarUrl: cachedAvatar['url'],
      );
    }

    return hydrated;
  }

  Future<void> saveAvatarLocally({
    required String ownerId,
    required String assetId,
    required String? url,
  }) async {
    await _sessionStore.saveAvatarForOwner(
      ownerId: ownerId,
      assetId: assetId,
      url: url,
    );
  }

  Future<void> saveOwnerLocally(Owner owner) => _sessionStore.saveOwner(owner);
}
