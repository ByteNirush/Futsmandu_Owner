enum KycVerificationStatus { pending, approved, rejected }

class Owner {
  const Owner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isVerified,
    required this.isActive,
    this.createdAt,
    this.businessName,
    this.role,
    bool? isKycApproved,
    KycVerificationStatus? kycStatus,
    this.kycRejectionReason,
    this.kycDocumentKeys = const <String, String>{},
  }) : isKycApproved =
           isKycApproved ?? kycStatus == KycVerificationStatus.approved,
       kycStatus =
           kycStatus ??
           (isKycApproved == true
               ? KycVerificationStatus.approved
               : KycVerificationStatus.pending);

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? createdAt;
  final String? businessName;
  final String? role;
  final bool isVerified;
  final bool isActive;
  final bool isKycApproved;
  final KycVerificationStatus kycStatus;
  final String? kycRejectionReason;
  final Map<String, String> kycDocumentKeys;

  static const List<String> _requiredKycDocTypes = <String>[
    'citizenship',
    'business_registration',
    'business_pan',
  ];

  bool get canAccessOwnerWorkspace => isActive && isVerified;
  bool get hasCompletedKyc => isKycApproved;
  bool get isOwnerAdmin => role?.toUpperCase() == 'OWNER_ADMIN';
  bool get hasUploadedAnyKycDocument => kycDocumentKeys.isNotEmpty;
  bool get hasUploadedAllKycDocuments =>
      _requiredKycDocTypes.every(kycDocumentKeys.containsKey);

  String get kycStatusLabel {
    switch (kycStatus) {
      case KycVerificationStatus.approved:
        return 'KYC Approved';
      case KycVerificationStatus.rejected:
        return 'KYC Rejected';
      case KycVerificationStatus.pending:
        return hasUploadedAnyKycDocument ? 'KYC Pending Review' : 'KYC Pending';
    }
  }

  String get displayBusinessName {
    final value = businessName?.trim();
    return value == null || value.isEmpty ? name : value;
  }

  String get displayRole {
    final value = role?.trim();
    return value == null || value.isEmpty ? 'OWNER_ADMIN' : value;
  }

  factory Owner.fromApiJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at']?.toString() ?? json['createdAt']?.toString();
    final isApproved =
        json['isKycApproved'] == true || json['is_kyc_approved'] == true;
    final docKeys = _parseKycDocumentKeys(json);
    final rejectionReason = _parseKycRejectionReason(json);
    final status = _parseKycStatus(
      json,
      isApproved: isApproved,
      hasDocuments: docKeys.isNotEmpty,
      rejectionReason: rejectionReason,
    );

    return Owner(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      createdAt: createdAtValue == null || createdAtValue.isEmpty
          ? null
          : DateTime.tryParse(createdAtValue),
      businessName: json['business_name']?.toString(),
      role: json['role']?.toString(),
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] != false,
      isKycApproved: status == KycVerificationStatus.approved,
      kycStatus: status,
      kycRejectionReason: rejectionReason,
      kycDocumentKeys: docKeys,
    );
  }

  factory Owner.fromStorageJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at']?.toString();
    final docKeys = _parseKycDocumentKeys(json);
    final rejectionReason = _parseKycRejectionReason(json);
    final isApproved =
        json['isKycApproved'] == true || json['is_kyc_approved'] == true;
    final status = _parseKycStatus(
      json,
      isApproved: isApproved,
      hasDocuments: docKeys.isNotEmpty,
      rejectionReason: rejectionReason,
    );

    return Owner(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      createdAt: createdAtValue == null || createdAtValue.isEmpty
          ? null
          : DateTime.tryParse(createdAtValue),
      businessName: json['business_name']?.toString(),
      role: json['role']?.toString(),
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] != false,
      isKycApproved: status == KycVerificationStatus.approved,
      kycStatus: status,
      kycRejectionReason: rejectionReason,
      kycDocumentKeys: docKeys,
    );
  }

  Map<String, dynamic> toStorageJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'business_name': businessName,
      'role': role,
      'is_verified': isVerified,
      'is_active': isActive,
      'is_kyc_approved': isKycApproved,
      'kyc_status': kycStatus.name,
      if (kycRejectionReason != null && kycRejectionReason!.trim().isNotEmpty)
        'kyc_rejection_reason': kycRejectionReason,
      'kyc_document_keys': kycDocumentKeys,
    };
  }

  Owner copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
    String? businessName,
    String? role,
    bool? isVerified,
    bool? isActive,
    bool? isKycApproved,
    KycVerificationStatus? kycStatus,
    String? kycRejectionReason,
    Map<String, String>? kycDocumentKeys,
  }) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isKycApproved: isKycApproved ?? this.isKycApproved,
      kycStatus: kycStatus ?? this.kycStatus,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      kycDocumentKeys: kycDocumentKeys ?? this.kycDocumentKeys,
    );
  }

  static KycVerificationStatus _parseKycStatus(
    Map<String, dynamic> json, {
    required bool isApproved,
    required bool hasDocuments,
    required String? rejectionReason,
  }) {
    final verificationDocs = _asMap(json['verification_docs']);
    final rawStatusValues = <Object?>[
      json['kyc_status'],
      json['kycStatus'],
      json['verification_status'],
      json['verificationStatus'],
      verificationDocs?['status'],
      verificationDocs?['kyc_status'],
      verificationDocs?['verification_status'],
    ];

    for (final rawValue in rawStatusValues) {
      final normalized = rawValue?.toString().trim().toLowerCase();
      if (normalized == null || normalized.isEmpty) {
        continue;
      }
      if (normalized.contains('approve') || normalized.contains('verify')) {
        return KycVerificationStatus.approved;
      }
      if (normalized.contains('reject') || normalized.contains('declin')) {
        return KycVerificationStatus.rejected;
      }
      if (normalized.contains('pending') ||
          normalized.contains('review') ||
          normalized.contains('submit')) {
        return KycVerificationStatus.pending;
      }
    }

    if (isApproved) {
      return KycVerificationStatus.approved;
    }
    if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
      return KycVerificationStatus.rejected;
    }
    if (hasDocuments) {
      return KycVerificationStatus.pending;
    }

    return KycVerificationStatus.pending;
  }

  static String? _parseKycRejectionReason(Map<String, dynamic> json) {
    final verificationDocs = _asMap(json['verification_docs']);
    final candidates = <Object?>[
      json['kyc_rejection_reason'],
      json['kycRejectionReason'],
      json['rejection_reason'],
      json['rejectionReason'],
      verificationDocs?['kyc_rejection_reason'],
      verificationDocs?['kycRejectionReason'],
      verificationDocs?['rejection_reason'],
      verificationDocs?['rejectionReason'],
      verificationDocs?['reason'],
    ];

    for (final candidate in candidates) {
      final reason = candidate?.toString().trim();
      if (reason != null && reason.isNotEmpty) {
        return reason;
      }
    }

    return null;
  }

  static Map<String, String> _parseKycDocumentKeys(Map<String, dynamic> json) {
    final parsed = <String, String>{};
    final verificationDocs = _asMap(json['verification_docs']);
    final explicitKycDocs = _asMap(json['kyc_document_keys']) ??
        _asMap(json['kycDocumentKeys']) ??
        _asMap(json['kyc_documents']) ??
        _asMap(json['kycDocuments']);

    for (final docType in _requiredKycDocTypes) {
      final key = _extractStringValue(explicitKycDocs?[docType]) ??
          _extractStringValue(verificationDocs?[docType]);
      if (key != null && key.isNotEmpty) {
        parsed[docType] = key;
      }
    }

    return parsed;
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  static String? _extractStringValue(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      return raw.trim();
    }
    if (raw is Map) {
      final map = _asMap(raw);
      final value = map?['key'] ?? map?['path'] ?? map?['url'];
      return value?.toString().trim();
    }
    return raw.toString().trim();
  }
}

typedef OwnerAuthProfile = Owner;

class Token {
  const Token({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;

  bool get isValid => accessToken.trim().isNotEmpty;

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'tokenType': tokenType,
    };
  }
}

class AuthResponse {
  const AuthResponse({required this.token, this.owner});

  final Token token;
  final Owner? owner;

  bool get hasOwner => owner != null;

  factory AuthResponse.fromLoginJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'];
    if (ownerJson is! Map<String, dynamic>) {
      throw const FormatException('Missing owner in authentication response.');
    }

    return AuthResponse(
      token: Token.fromJson(json),
      owner: Owner.fromApiJson(ownerJson),
    );
  }

  factory AuthResponse.fromRefreshJson(Map<String, dynamic> json) {
    return AuthResponse(token: Token.fromJson(json));
  }
}

class OwnerRegistrationResult {
  const OwnerRegistrationResult({
    required this.message,
    required this.owner,
    required this.pendingVerification,
  });

  final String message;
  final Owner owner;
  final bool pendingVerification;

  factory OwnerRegistrationResult.fromApiJson(Map<String, dynamic> json) {
    return OwnerRegistrationResult(
      message: 'Owner account created. Verify the OTP sent to your email.',
      owner: Owner.fromApiJson(json),
      pendingVerification: true,
    );
  }
}

class OwnerLoginResult {
  const OwnerLoginResult({
    required this.accessToken,
    required this.owner,
    this.refreshToken,
  });

  final String accessToken;
  final Owner owner;
  final String? refreshToken;
}

class OtpVerificationResult {
  const OtpVerificationResult({required this.success, required this.message});

  final bool success;
  final String message;

  factory OtpVerificationResult.fromJson(Map<String, dynamic> json) {
    return OtpVerificationResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'OTP verification failed.',
    );
  }
}
