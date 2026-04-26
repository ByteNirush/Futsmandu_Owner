import 'package:flutter/foundation.dart';

import '../../../../core/network/error_handler.dart';
import '../../data/owner_auth_repository.dart';
import '../../domain/owner_auth_models.dart';

enum OwnerAuthStatus { initializing, unauthenticated, authenticated }

const bool kBypassKycVerification = false;

class OwnerAuthController extends ChangeNotifier {
  OwnerAuthController({OwnerAuthRepository? repository})
    : _repository = repository ?? OwnerAuthRepository();

  final OwnerAuthRepository _repository;

  OwnerAuthStatus _status = OwnerAuthStatus.initializing;
  OwnerAuthProfile? _owner;
  bool _isBusy = false;
  String? _errorMessage;

  OwnerAuthStatus get status => _status;
  OwnerAuthProfile? get owner => _owner;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == OwnerAuthStatus.authenticated;
  bool get isVerified => _owner?.isVerified ?? false;
  bool get isKycApproved => _owner?.isKycApproved ?? false;
    KycVerificationStatus get kycStatus =>
      _owner?.kycStatus ?? KycVerificationStatus.pending;
    String? get kycRejectionReason => _owner?.kycRejectionReason;
    bool get hasUploadedAnyKycDocument =>
      _owner?.hasUploadedAnyKycDocument ?? false;
    bool get hasUploadedAllKycDocuments =>
      _owner?.hasUploadedAllKycDocuments ?? false;
  
  /// Can access the dashboard and basic features
  bool get canAccessWorkspace => isAuthenticated;
  
  /// Indicates KYC is still pending review
  bool get needsKycVerification =>
      isAuthenticated && !kBypassKycVerification && !isKycApproved;
  
  /// For backward compatibility - email verification status
  bool get needsVerification =>
      isAuthenticated && !kBypassKycVerification && !isVerified;
  
  bool get isInitializing => _status == OwnerAuthStatus.initializing;

  Future<void> bootstrap() async {
    _setStatus(OwnerAuthStatus.initializing);
    try {
      final owner = await _repository.restoreSession();
      if (owner == null) {
        _owner = null;
        _setStatus(OwnerAuthStatus.unauthenticated);
        return;
      }

      _owner = owner;
      _setStatus(OwnerAuthStatus.authenticated);
    } catch (error) {
      _owner = null;
      _errorMessage = ErrorHandler.messageFor(error);
      _setStatus(OwnerAuthStatus.unauthenticated);
    }
  }

  Future<OwnerRegistrationResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? businessName,
  }) async {
    _startBusy();
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        businessName: businessName,
      );
      _clearError();
      return result;
    } catch (error) {
      _errorMessage = ErrorHandler.messageFor(error);
      rethrow;
    } finally {
      _endBusy();
    }
  }

  Future<OtpVerificationResult> verifyOtp({
    required String ownerId,
    required String otp,
  }) async {
    _startBusy();
    try {
      final response = await _repository.verifyOtp(ownerId: ownerId, otp: otp);
      _clearError();
      return response;
    } catch (error) {
      _errorMessage = ErrorHandler.messageFor(error);
      rethrow;
    } finally {
      _endBusy();
    }
  }

  Future<String> resendOtp({required String ownerId}) async {
    _startBusy();
    try {
      final message = await _repository.resendOtp(ownerId: ownerId);
      _clearError();
      return message;
    } catch (error) {
      _errorMessage = ErrorHandler.messageFor(error);
      rethrow;
    } finally {
      _endBusy();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _startBusy();
    try {
      _owner = await _repository.login(email: email, password: password);
      _clearError();
      _setStatus(OwnerAuthStatus.authenticated);
    } catch (error) {
      _owner = null;
      _errorMessage = ErrorHandler.messageFor(error);
      _setStatus(OwnerAuthStatus.unauthenticated);
      rethrow;
    } finally {
      _endBusy();
    }
  }

  Future<void> logout() async {
    _startBusy();
    try {
      await _repository.logout();
    } catch (error) {
      _errorMessage = ErrorHandler.messageFor(error);
      await _repository.clearSession();
    } finally {
      _owner = null;
      _setStatus(OwnerAuthStatus.unauthenticated);
      _endBusy();
    }
  }

  Future<void> refreshSession() async {
    try {
      await _repository.refreshAccessToken();
      if (_owner != null) {
        _setStatus(OwnerAuthStatus.authenticated);
      }
    } catch (error) {
      _owner = null;
      _errorMessage = ErrorHandler.messageFor(error);
      await _repository.clearSession();
      _setStatus(OwnerAuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> updateAvatar(String assetId, String? cdnUrl) async {
    if (_owner == null) return;

    // 1. Update in-memory state
    _owner = _owner!.copyWith(
      avatarAssetId: assetId,
      avatarUrl: cdnUrl,
    );

    // 2. Persist locally (since backend won't save it)
    await _repository.saveAvatarLocally(
      ownerId: _owner!.id,
      assetId: assetId,
      url: cdnUrl,
    );
    
    // 3. Save the whole owner object to session store too
    await _repository.saveOwnerLocally(_owner!);

    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setStatus(OwnerAuthStatus status) {
    if (_status == status) {
      notifyListeners();
      return;
    }
    _status = status;
    notifyListeners();
  }

  void _startBusy() {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
  }

  void _endBusy() {
    if (!_isBusy) return;
    _isBusy = false;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
  }
}
