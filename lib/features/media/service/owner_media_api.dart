import 'package:dio/dio.dart';

import '../../../core/config/owner_api_config.dart';
import '../../../core/network/debug_dio_logging_interceptor.dart';
import '../../../core/network/owner_api_client.dart';
import '../model/media_upload_models.dart';

// ============================================================================
// OwnerMediaApi  —  Step 1 (get presigned URL) + Step 3 (confirm / status)
// Each asset type calls its own dedicated server endpoint per the Swagger spec.
// ============================================================================

class OwnerMediaApi {
  OwnerMediaApi({OwnerApiClient? apiClient})
      : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  // --------------------------------------------------------------------------
  // Step 1 helpers — one method per asset type
  // --------------------------------------------------------------------------

  /// KYC document
  /// POST /api/v1/owner/media/kyc/upload-url
  Future<MediaUploadUrlResponse> requestKycUploadUrl({
    required OwnerKycDocType docType,
    String? contentType,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.mediaKycUploadUrlEndpoint,
      data: KycUploadUrlRequest(
        docType: docType,
        contentType: contentType,
      ).toJson(),
    );
    return _parseUploadUrlResponse(response);
  }

  /// Owner avatar
  /// POST /api/v1/owner/media/profile/avatar/upload-url
  Future<MediaUploadUrlResponse> requestAvatarUploadUrl({
    String? contentType,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.mediaAvatarUploadUrlEndpoint,
      data: AvatarUploadUrlRequest(contentType: contentType).toJson(),
    );
    return _parseUploadUrlResponse(response);
  }

  /// Venue cover image
  /// POST /api/v1/owner/media/venues/{venueId}/cover/upload-url
  Future<MediaUploadUrlResponse> requestVenueCoverUploadUrl({
    required String venueId,
    String? contentType,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.venueCoverUploadUrlEndpoint(venueId),
      data: VenueMediaUploadUrlRequest(contentType: contentType).toJson(),
    );
    return _parseUploadUrlResponse(response);
  }

  /// Venue gallery image
  /// POST /api/v1/owner/media/venues/{venueId}/gallery/upload-url
  Future<MediaUploadUrlResponse> requestVenueGalleryUploadUrl({
    required String venueId,
    String? contentType,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.venueGalleryUploadUrlEndpoint(venueId),
      data: VenueMediaUploadUrlRequest(contentType: contentType).toJson(),
    );
    return _parseUploadUrlResponse(response);
  }

  /// Venue verification document
  /// POST /api/v1/owner/media/venues/{venueId}/verification/upload-url
  Future<MediaUploadUrlResponse> requestVenueVerificationUploadUrl({
    required String venueId,
    String? contentType,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.venueVerificationUploadUrlEndpoint(venueId),
      data: VenueMediaUploadUrlRequest(contentType: contentType).toJson(),
    );
    return _parseUploadUrlResponse(response);
  }

  // --------------------------------------------------------------------------
  // Step 3 — Confirm upload
  // POST /api/v1/owner/media/confirm-upload
  // --------------------------------------------------------------------------

  Future<MediaConfirmUploadResponse> confirmUpload(
    MediaConfirmUploadRequest request,
  ) async {
    final response = await _apiClient.post(
      OwnerApiConfig.mediaConfirmUploadEndpoint,
      data: request.toJson(),
    );
    return MediaConfirmUploadResponse.fromJson(response);
  }

  // --------------------------------------------------------------------------
  // Status polling
  // GET /api/v1/owner/media/status/{assetId}
  // --------------------------------------------------------------------------

  Future<MediaAssetStatusResponse> getUploadStatus(String assetId) async {
    final response = await _apiClient.get(
      OwnerApiConfig.mediaStatusEndpoint(assetId),
    );
    return MediaAssetStatusResponse.fromJson(response);
  }

  // --------------------------------------------------------------------------
  // Signed download URL for private assets (KYC / venue verification)
  // POST /api/v1/owner/media/download-url
  // --------------------------------------------------------------------------

  Future<MediaDownloadUrlResponse> getDownloadUrl({
    required String key,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.mediaDownloadUrlEndpoint,
      data: MediaDownloadUrlRequest(key: key).toJson(),
    );
    return MediaDownloadUrlResponse.fromJson(response);
  }

  // --------------------------------------------------------------------------
  // Delete asset
  // DELETE /api/v1/owner/media/asset?assetId={assetId}
  // --------------------------------------------------------------------------

  Future<void> deleteAsset(String assetId) async {
    await _apiClient.delete(
      OwnerApiConfig.mediaDeleteAssetEndpoint(assetId),
    );
  }
  /// Fetch all KYC documents for owner
  /// GET /api/v1/owner/media/kyc
  /// Includes retry logic with exponential backoff for 429 rate limit errors.
  /// --------------------------------------------------------------------------

  Future<FetchKycDocumentsResponse> fetchAllKycDocuments() async {
    const maxRetries = 3;
    const baseDelayMs = 500;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get(
          OwnerApiConfig.mediaKycListEndpoint,
        );

        final normalized = <String, dynamic>{
          if (response['data'] != null) 'data': response['data'],
          if (response['items'] != null) 'items': response['items'],
          if (response['value'] != null) 'value': response['value'],
        };

        return FetchKycDocumentsResponse.fromApiResponse(
          normalized.isEmpty ? response : normalized,
        );
      } on DioException catch (e) {
        final is429 = e.response?.statusCode == 429;
        final isLastAttempt = attempt == maxRetries;

        if (is429 && !isLastAttempt) {
          final delayMs = baseDelayMs * (1 << attempt); // exponential: 500, 1000, 2000ms
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Failed to fetch KYC documents after $maxRetries retries');
  }

  // --------------------------------------------------------------------------
  // Fetch venue gallery images
  // GET /api/v1/owner/media/venues/{venueId}/gallery
  // --------------------------------------------------------------------------

  Future<List<VenueGalleryImage>> fetchVenueGallery(String venueId) async {
    final response = await _apiClient.get(
      OwnerApiConfig.mediaVenueGalleryEndpoint(venueId),
    );

    final data = response['data'] ?? response;
    if (data is! List) return [];

    return data
        .map((item) => VenueGalleryImage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  MediaUploadUrlResponse _parseUploadUrlResponse(dynamic response) {
    final parsed = MediaUploadUrlResponse.fromJson(
      response as Map<String, dynamic>,
    );
    if (parsed.uploadUrl.isEmpty || parsed.key.isEmpty) {
      throw ApiException('Invalid upload URL response from server.');
    }
    return parsed;
  }
}

// ============================================================================
// OwnerMediaStorageUploader  —  Step 2: PUT bytes to R2 presigned URL
// This call goes directly to R2, not through the owner API server.
// ============================================================================

class OwnerMediaStorageUploader {
  OwnerMediaStorageUploader({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 120),
              ),
            )..interceptors.add(DebugDioLoggingInterceptor());

  final Dio _dio;

  Future<void> uploadBytes({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Map<String, String> headers = const <String, String>{},
    void Function(double progress)? onProgress,
  }) async {
    await _dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          ...headers,
          // Only inject Content-Type if the server didn't already supply it.
          if (!headers.keys
              .any((k) => k.toLowerCase() == 'content-type'))
            'Content-Type': contentType,
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress == null || total <= 0) return;
        onProgress(sent / total);
      },
    );
  }
}
