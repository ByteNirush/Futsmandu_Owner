// ============================================================================
// Media Upload Models
// Aligned with Futsmandu Owner API v1 — swagger spec.
// ============================================================================

/// Each asset type maps to a dedicated server endpoint (Step 1).
enum OwnerMediaAssetType {
  ownerAvatar('owner_profile'),
  kycDocument('kyc_document'),
  venueCover('venue_cover'),
  venueGallery('venue_gallery'),
  venueVerification('venue_verification');

  const OwnerMediaAssetType(this.value);
  final String value;
}

/// KYC document sub-type — sent to the KYC upload-url endpoint.
enum OwnerKycDocType {
  citizenship('citizenship'),
  businessRegistration('business_registration'),
  businessPan('business_pan');

  const OwnerKycDocType(this.value);
  final String value;
}

// ---------------------------------------------------------------------------
// Step 1 — Request presigned upload URL from server
// ---------------------------------------------------------------------------

/// Body for POST /media/kyc/upload-url
class KycUploadUrlRequest {
  const KycUploadUrlRequest({
    required this.docType,
    this.contentType,
  });

  final OwnerKycDocType docType;
  final String? contentType;

  Map<String, dynamic> toJson() => {
        'docType': docType.value,
        if (contentType != null && contentType!.isNotEmpty)
          'contentType': contentType,
      };
}

/// Body for POST /media/profile/avatar/upload-url
/// (no extra fields required beyond auth token)
class AvatarUploadUrlRequest {
  const AvatarUploadUrlRequest({this.contentType});
  final String? contentType;

  Map<String, dynamic> toJson() => {
        if (contentType != null && contentType!.isNotEmpty)
          'contentType': contentType,
      };
}

/// Body for POST /media/venues/{venueId}/cover/upload-url
/// Body for POST /media/venues/{venueId}/gallery/upload-url
/// Body for POST /media/venues/{venueId}/verification/upload-url
/// (venueId lives in the path; optionally send contentType)
class VenueMediaUploadUrlRequest {
  const VenueMediaUploadUrlRequest({this.contentType});
  final String? contentType;

  Map<String, dynamic> toJson() => {
        if (contentType != null && contentType!.isNotEmpty)
          'contentType': contentType,
      };
}

// ---------------------------------------------------------------------------
// Step 1 — Response: presigned URL + R2 key
// ---------------------------------------------------------------------------

class MediaUploadUrlResponse {
  const MediaUploadUrlResponse({
    required this.uploadUrl,
    required this.key,
    required this.expiresIn,
    this.cdnUrl,
    this.headers = const <String, String>{},
    this.assetId,
  });

  final String uploadUrl;
  final String key;
  final int expiresIn;
  final String? assetId;

  /// CDN-accessible URL (available after processing completes).
  final String? cdnUrl;

  /// Extra headers that must be forwarded in the PUT request to R2.
  final Map<String, String> headers;

  factory MediaUploadUrlResponse.fromJson(Map<String, dynamic> json) {
    final parsedHeaders = <String, String>{};
    final rawHeaders = json['headers'];
    if (rawHeaders is Map<String, dynamic>) {
      for (final entry in rawHeaders.entries) {
        final k = entry.key.trim();
        final v = entry.value?.toString().trim();
        if (k.isNotEmpty && v != null && v.isNotEmpty) {
          parsedHeaders[k] = v;
        }
      }
    }

    return MediaUploadUrlResponse(
      uploadUrl: (json['uploadUrl'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      expiresIn: _toInt(json['expiresIn']),
      cdnUrl: (json['cdnUrl'] as String?) ?? (json['cdn_url'] as String?),
      headers: parsedHeaders,
      assetId: (json['assetId'] as String?) ?? (json['asset_id'] as String?),
    );
  }

  static int _toInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Confirm upload
// ---------------------------------------------------------------------------

/// Body for POST /media/confirm-upload
class MediaConfirmUploadRequest {
  const MediaConfirmUploadRequest({
    required this.key,
    required this.assetType,
    this.assetId,
  });

  final String key;
  final OwnerMediaAssetType assetType;
  final String? assetId;

  Map<String, dynamic> toJson() => {
        'key': key,
        'assetType': assetType.value,
        if (assetId != null) 'assetId': assetId,
      };
}

class MediaConfirmUploadResponse {
  const MediaConfirmUploadResponse({
    required this.message,
    this.assetId,
    this.status,
  });

  final String message;
  final String? assetId;
  final String? status;

  factory MediaConfirmUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaConfirmUploadResponse(
      message: (json['message'] as String?) ?? 'Upload confirmed.',
      assetId: (json['assetId'] as String?) ??
          (json['asset_id'] as String?) ??
          (json['id'] as String?),
      status: (json['status'] as String?) ?? (json['assetStatus'] as String?),
    );
  }
}

// ---------------------------------------------------------------------------
// Status polling
// ---------------------------------------------------------------------------

class MediaAssetStatusResponse {
  const MediaAssetStatusResponse({
    required this.status,
    this.progress,
    this.webpUrl,
    this.thumbUrl,
  });

  final String status;

  /// Processing progress 0–100, if provided by the backend.
  final int? progress;

  /// CDN URL of the processed WebP variant (available when status = ready).
  final String? webpUrl;

  /// CDN URL of the 320×240 thumbnail (available when status = ready).
  final String? thumbUrl;

  bool get isReady {
    final normalized = status.toLowerCase();
    return normalized == 'completed' || normalized == 'ready';
  }
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isProcessing => status.toLowerCase() == 'processing';

  factory MediaAssetStatusResponse.fromJson(Map<String, dynamic> json) {
    return MediaAssetStatusResponse(
      status: (json['status'] as String?) ?? 'processing',
      progress: json['progress'] as int?,
      // Backend returns camelCase: webpKey, thumbUrl
      // We surface the fully-qualified CDN URLs directly.
      webpUrl:  (json['webpUrl']  as String?) ??
                (json['webp_url'] as String?),
      thumbUrl: (json['thumbUrl'] as String?) ??
                (json['thumb_url'] as String?),
    );
  }
}

// ---------------------------------------------------------------------------
// Aggregate result returned to UI after the full 3-step pipeline
// ---------------------------------------------------------------------------

class MediaUploadResult {
  const MediaUploadResult({
    required this.key,
    required this.confirmMessage,
    required this.status,
    this.cdnUrl,
    this.assetId,
    this.webpUrl,
    this.thumbUrl,
  });

  final String key;
  final String confirmMessage;
  final MediaAssetStatusResponse status;
  final String? cdnUrl;
  final String? assetId;

  /// Processed WebP CDN URL (set after polling completes with status = ready).
  final String? webpUrl;

  /// 320×240 thumbnail CDN URL (set after polling completes with status = ready).
  final String? thumbUrl;

  bool get isReady => status.isReady;

  /// Best available display URL: prefer processed WebP > raw CDN URL.
  String? get imageUrl => webpUrl ?? cdnUrl;
}

// ---------------------------------------------------------------------------
// Download URL (for private assets: KYC / venue verification)
// ---------------------------------------------------------------------------

class MediaDownloadUrlRequest {
  const MediaDownloadUrlRequest({required this.key});
  final String key;

  Map<String, dynamic> toJson() => {'key': key};
}

class MediaDownloadUrlResponse {
  const MediaDownloadUrlResponse({required this.downloadUrl, this.expiresIn});
  final String downloadUrl;
  final int? expiresIn;

  factory MediaDownloadUrlResponse.fromJson(Map<String, dynamic> json) {
    return MediaDownloadUrlResponse(
      downloadUrl:
          (json['downloadUrl'] as String?) ?? (json['url'] as String?) ?? '',
      expiresIn: json['expiresIn'] as int?,
    );
  }
}

// ---------------------------------------------------------------------------
// Fetch all KYC documents for owner
// GET /api/v1/owner/media/kyc
// ---------------------------------------------------------------------------

class KycDocumentItem {
  const KycDocumentItem({
    required this.assetId,
    required this.docType,
    required this.downloadUrl,
    this.expiresIn,
    this.kycStatus,
    this.rejectionReason,
  });

  final String assetId;
  final String docType;
  final String downloadUrl;
  final int? expiresIn;
  final String? kycStatus;
  final String? rejectionReason;

  factory KycDocumentItem.fromJson(Map<String, dynamic> json) {
    return KycDocumentItem(
      assetId: (json['assetId'] as String?) ??
          (json['asset_id'] as String?) ??
          '',
      docType: (json['docType'] as String?) ??
          (json['doc_type'] as String?) ??
          '',
      downloadUrl: (json['downloadUrl'] as String?) ??
          (json['download_url'] as String?) ??
          '',
      expiresIn: json['expiresIn'] as int? ?? json['expires_in'] as int?,
      kycStatus: (json['kycStatus'] as String?) ?? (json['kyc_status'] as String?),
      rejectionReason: (json['rejectionReason'] as String?) ??
          (json['rejection_reason'] as String?),
    );
  }

  /// Convert docType string to OwnerKycDocType enum
  OwnerKycDocType? get kycDocType {
    try {
      return OwnerKycDocType.values
          .firstWhere((e) => e.value == docType);
    } catch (e) {
      return null;
    }
  }
}

class FetchKycDocumentsResponse {
  const FetchKycDocumentsResponse({required this.documents});

  final List<KycDocumentItem> documents;

  factory FetchKycDocumentsResponse.fromApiResponse(dynamic raw) {
    final dataList = _extractDocumentsList(raw);

    final documents = dataList
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(KycDocumentItem.fromJson)
        .where((item) => item.docType.isNotEmpty && item.downloadUrl.isNotEmpty)
        .toList();

    return FetchKycDocumentsResponse(documents: documents);
  }

  static List<dynamic> _extractDocumentsList(dynamic raw) {
    if (raw is List<dynamic>) {
      return raw;
    }

    if (raw is Map<String, dynamic>) {
      final keys = <String>['data', 'items', 'value'];
      for (final key in keys) {
        final candidate = raw[key];
        if (candidate is List<dynamic>) {
          return candidate;
        }
      }

      for (final key in keys) {
        final candidate = raw[key];
        if (candidate is Map<String, dynamic>) {
          final nested = _extractDocumentsList(candidate);
          if (nested.isNotEmpty) {
            return nested;
          }
        }
      }
    }

    return const <dynamic>[];
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
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
}

// ---------------------------------------------------------------------------
// Venue Gallery Image
// GET /api/v1/owner/media/venues/{venueId}/gallery response item
// ---------------------------------------------------------------------------

class VenueGalleryImage {
  const VenueGalleryImage({
    required this.assetId,
    required this.cdnUrl,
    this.key,
    this.thumbUrl,
    this.webpUrl,
    this.uploadedAt,
  });

  final String assetId;
  final String cdnUrl;
  final String? key;
  final String? thumbUrl;
  final String? webpUrl;
  final DateTime? uploadedAt;

  /// Best available display URL: prefer WebP > CDN URL
  String get displayUrl => webpUrl ?? cdnUrl;

  factory VenueGalleryImage.fromJson(Map<String, dynamic> json) {
    return VenueGalleryImage(
      assetId: (json['asset_id'] as String?) ??
          (json['assetId'] as String?) ??
          '',
      key: (json['key'] as String?),
      cdnUrl: (json['cdn_url'] as String?) ??
          (json['cdnUrl'] as String?) ??
          '',
      thumbUrl: (json['thumb_url'] as String?) ?? (json['thumbUrl'] as String?),
      webpUrl: (json['webp_url'] as String?) ?? (json['webpUrl'] as String?),
      uploadedAt: _parseDate(json['uploaded_at'] ?? json['uploadedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
