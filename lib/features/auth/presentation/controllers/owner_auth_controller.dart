import 'package:flutter/foundation.dart';

import '../../data/owner_auth_repository.dart';
import '../../domain/owner_auth_models.dart';

enum OwnerAuthStatus { initializing, unauthenticated, authenticated }

const bool kBypassOwnerAdminVerification = true;

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
  bool get canAccessWorkspace =>
      isAuthenticated && (kBypassOwnerAdminVerification || isVerified);
  bool get needsVerification =>
      isAuthenticated && !kBypassOwnerAdminVerification && !isVerified;
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
      _errorMessage = _readableError(error);
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
      _errorMessage = _readableError(error);
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
      _errorMessage = _readableError(error);
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
      _errorMessage = _readableError(error);
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
      _errorMessage = _readableError(error);
      await _repository.clearSession();
      _setStatus(OwnerAuthStatus.unauthenticated);
      rethrow;
    }
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

  String _readableError(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}
