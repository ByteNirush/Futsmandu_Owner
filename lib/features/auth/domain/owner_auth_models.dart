class OwnerAuthProfile {
  const OwnerAuthProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isVerified,
    required this.isActive,
    this.businessName,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? businessName;
  final bool isVerified;
  final bool isActive;

  bool get canAccessOwnerWorkspace => isActive && isVerified;

  String get displayBusinessName {
    final value = businessName?.trim();
    return value == null || value.isEmpty ? name : value;
  }

  factory OwnerAuthProfile.fromLoginResponse(Map<String, dynamic> json) {
    return OwnerAuthProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      businessName: json['business_name']?.toString(),
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] != false,
    );
  }

  factory OwnerAuthProfile.fromStorageJson(Map<String, dynamic> json) {
    return OwnerAuthProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      businessName: json['business_name']?.toString(),
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toStorageJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'business_name': businessName,
      'is_verified': isVerified,
      'is_active': isActive,
    };
  }
}

class OwnerRegistrationResult {
  const OwnerRegistrationResult({
    required this.message,
    required this.ownerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.pendingVerification,
    this.businessName,
    this.createdAt,
  });

  final String message;
  final String ownerId;
  final String name;
  final String email;
  final String phone;
  final String? businessName;
  final DateTime? createdAt;
  final bool pendingVerification;

  factory OwnerRegistrationResult.fromApiJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at']?.toString();
    return OwnerRegistrationResult(
      message: 'Pending admin verification',
      ownerId: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      businessName: json['business_name']?.toString(),
      createdAt: createdAtValue == null || createdAtValue.isEmpty
          ? null
          : DateTime.tryParse(createdAtValue),
      pendingVerification: true,
    );
  }
}

class OwnerLoginResult {
  const OwnerLoginResult({required this.accessToken, required this.owner});

  final String accessToken;
  final OwnerAuthProfile owner;
}
