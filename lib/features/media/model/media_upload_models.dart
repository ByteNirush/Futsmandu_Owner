enum OwnerMediaAssetType {
  ownerProfile('owner_profile'),
  kycDocument('kyc_document'),
  venueCover('venue_cover'),
  venueGallery('venue_gallery'),
  venueVerification('venue_verification');

  const OwnerMediaAssetType(this.value);
  final String value;
}

enum OwnerKycDocType {
  citizenship('citizenship'),
  businessRegistration('business_registration'),
  businessPan('business_pan');

  const OwnerKycDocType(this.value);
  final String value;
}

class MediaUploadUrlRequest {
  const MediaUploadUrlRequest({
    required this.assetType,
    required this.entityId,
    this.docType,
    this.contentType,
  });

  final OwnerMediaAssetType assetType;
  final String entityId;
  final OwnerKycDocType? docType;
  final String? contentType;

  Map<String, dynamic> toJson() {
    return {
      'assetType': assetType.value,
      'entityId': entityId.trim(),
      if (docType != null) 'docType': docType!.value,
      if (contentType != null && contentType!.trim().isNotEmpty)
        'contentType': contentType!.trim(),
    };
  }
}

class MediaUploadUrlResponse {
  const MediaUploadUrlResponse({
    required this.uploadUrl,
    required this.key,
    required this.expiresIn,
    this.cdnUrl,
    this.headers = const <String, String>{},
  });

  final String uploadUrl;
  final String key;
  final int expiresIn;
  final String? cdnUrl;
  final Map<String, String> headers;

  factory MediaUploadUrlResponse.fromJson(Map<String, dynamic> json) {
    final parsedHeaders = <String, String>{};
    final rawHeaders = json['headers'];
    if (rawHeaders is Map<String, dynamic>) {
      for (final entry in rawHeaders.entries) {
        final key = entry.key.trim();
        final value = entry.value?.toString().trim();
        if (key.isNotEmpty && value != null && value.isNotEmpty) {
          parsedHeaders[key] = value;
        }
      }
    }

    return MediaUploadUrlResponse(
      uploadUrl: (json['uploadUrl'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      expiresIn: _toInt(json['expiresIn']),
      cdnUrl: (json['cdnUrl'] as String?) ?? (json['cdn_url'] as String?),
      headers: parsedHeaders,
    );
  }

  static int _toInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

class MediaConfirmUploadRequest {
  const MediaConfirmUploadRequest({
    required this.key,
    required this.assetType,
  });

  final String key;
  final OwnerMediaAssetType assetType;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'assetType': assetType.value,
    };
  }
}

class MediaConfirmUploadResponse {
  const MediaConfirmUploadResponse({required this.message});

  final String message;

  factory MediaConfirmUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaConfirmUploadResponse(
      message: (json['message'] as String?) ?? 'Upload confirmed.',
    );
  }
}

class MediaUploadResult {
  const MediaUploadResult({
    required this.key,
    required this.confirmMessage,
    this.cdnUrl,
  });

  final String key;
  final String confirmMessage;
  final String? cdnUrl;
}
