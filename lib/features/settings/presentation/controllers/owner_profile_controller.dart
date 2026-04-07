import 'package:flutter/material.dart';

class OwnerProfileController extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _isVerified = true;
  bool _kycUpdated = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isVerified => _isVerified;
  bool get kycUpdated => _kycUpdated;

  String get verificationStatusLabel =>
      _isVerified ? 'Verified' : 'Not Verified';

  String get kycStatusLabel => _kycUpdated ? 'KYC Updated' : 'Pending';

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setVerified(bool value) {
    if (_isVerified == value) return;
    _isVerified = value;
    notifyListeners();
  }

  void markKycUpdated() {
    if (_kycUpdated) return;
    _kycUpdated = true;
    notifyListeners();
  }
}
