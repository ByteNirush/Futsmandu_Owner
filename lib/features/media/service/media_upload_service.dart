import '../model/media_upload_models.dart';
import 'media_status_poller.dart';
import 'owner_media_api.dart';
import 'uploaded_image_cache.dart';

// ============================================================================
// MediaUploadService
// Orchestrates the full 3-step upload pipeline:
//   Step 1 — POST to the correct per-type endpoint → get presigned URL
//   Step 2 — PUT bytes directly to R2
//   Step 3 — POST confirm-upload → optional status poll
// ============================================================================

class MediaUploadService {
  MediaUploadService({
    OwnerMediaApi? mediaApi,
    OwnerMediaStorageUploader? storageUploader,
    MediaStatusPoller? statusPoller,
  })  : _mediaApi = mediaApi ?? OwnerMediaApi(),
        _storageUploader = storageUploader ?? OwnerMediaStorageUploader(),
        _statusPoller = statusPoller ?? MediaStatusPoller();

  final OwnerMediaApi _mediaApi;
  final OwnerMediaStorageUploader _storageUploader;
  final MediaStatusPoller _statusPoller;

  // --------------------------------------------------------------------------
  // Public entry points — one per asset type for clarity at the call-site.
  // --------------------------------------------------------------------------

  /// Upload owner KYC document.
  Future<MediaUploadResult> uploadKycDocument({
    required OwnerKycDocType docType,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = false,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) {
    return _upload(
      getUploadUrl: () => _mediaApi.requestKycUploadUrl(
        docType: docType,
        contentType: contentType,
      ),
      assetType: OwnerMediaAssetType.kycDocument,
      bytes: bytes,
      contentType: contentType,
      pollUntilReady: pollUntilReady,
      onStatusMessage: onStatusMessage,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Upload owner profile avatar.
  Future<MediaUploadResult> uploadOwnerAvatar({
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = true,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) {
    return _upload(
      getUploadUrl: () => _mediaApi.requestAvatarUploadUrl(
        contentType: contentType,
      ),
      assetType: OwnerMediaAssetType.ownerAvatar,
      bytes: bytes,
      contentType: contentType,
      pollUntilReady: pollUntilReady,
      onStatusMessage: onStatusMessage,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Upload venue cover image.
  Future<MediaUploadResult> uploadVenueCover({
    required String venueId,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = true,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) {
    return _upload(
      getUploadUrl: () => _mediaApi.requestVenueCoverUploadUrl(
        venueId: venueId,
        contentType: contentType,
      ),
      assetType: OwnerMediaAssetType.venueCover,
      bytes: bytes,
      contentType: contentType,
      pollUntilReady: pollUntilReady,
      onStatusMessage: onStatusMessage,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Upload venue gallery image.
  Future<MediaUploadResult> uploadVenueGalleryImage({
    required String venueId,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = true,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) {
    return _upload(
      getUploadUrl: () => _mediaApi.requestVenueGalleryUploadUrl(
        venueId: venueId,
        contentType: contentType,
      ),
      assetType: OwnerMediaAssetType.venueGallery,
      bytes: bytes,
      contentType: contentType,
      pollUntilReady: pollUntilReady,
      onStatusMessage: onStatusMessage,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Upload venue verification document.
  Future<MediaUploadResult> uploadVenueVerification({
    required String venueId,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = false,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) {
    return _upload(
      getUploadUrl: () => _mediaApi.requestVenueVerificationUploadUrl(
        venueId: venueId,
        contentType: contentType,
      ),
      assetType: OwnerMediaAssetType.venueVerification,
      bytes: bytes,
      contentType: contentType,
      pollUntilReady: pollUntilReady,
      onStatusMessage: onStatusMessage,
      onUploadProgress: onUploadProgress,
    );
  }

  // --------------------------------------------------------------------------
  // Utility: fetch a signed download URL for a private asset.
  // --------------------------------------------------------------------------

  Future<String> getPrivateDownloadUrl(String key) async {
    final response = await _mediaApi.getDownloadUrl(key: key);
    return response.downloadUrl;
  }

  // --------------------------------------------------------------------------
  // Core pipeline (private)
  // --------------------------------------------------------------------------

  Future<MediaUploadResult> _upload({
    required Future<MediaUploadUrlResponse> Function() getUploadUrl,
    required OwnerMediaAssetType assetType,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = false,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) async {
    // Step 1 — Get presigned URL
    onStatusMessage?.call('Requesting upload URL…');
    final uploadUrlResponse = await getUploadUrl();

    // Step 2 — PUT bytes to R2
    onStatusMessage?.call('Uploading…');
    await _storageUploader.uploadBytes(
      uploadUrl: uploadUrlResponse.uploadUrl,
      bytes: bytes,
      contentType: contentType,
      headers: uploadUrlResponse.headers,
      onProgress: onUploadProgress,
    );

    // Step 3 — Confirm
    onStatusMessage?.call('Confirming upload…');
    final confirm = await _mediaApi.confirmUpload(
      MediaConfirmUploadRequest(
        key: uploadUrlResponse.key,
        assetType: assetType,
        assetId: uploadUrlResponse.assetId,
      ),
    );

    var status = MediaAssetStatusResponse(
      status: confirm.status ?? 'processing',
    );

    if (pollUntilReady && confirm.assetId != null) {
      onStatusMessage?.call('Waiting for processing…');
      status = await _pollUntilReady(confirm.assetId!);
    }

    onStatusMessage?.call(
      status.isReady ? 'Ready.' : 'Upload complete.',
    );

    final result = MediaUploadResult(
      key: uploadUrlResponse.key,
      cdnUrl: uploadUrlResponse.cdnUrl,
      confirmMessage: confirm.message,
      assetId: confirm.assetId,
      status: status,
    );

    // Cache the uploaded image immediately for instant UI display
    if (confirm.assetId != null) {
      uploadedImageCache.save(
        assetId: confirm.assetId!,
        key: uploadUrlResponse.key,
        cdnUrl: uploadUrlResponse.cdnUrl,
        imageBytes: bytes,
      );
    }

    return result;
  }

  Future<MediaAssetStatusResponse> _pollUntilReady(String assetId) async {
    final statusStream = _statusPoller.pollStatus(assetId);
    
    // Get the first status (or the current one)
    try {
      final status = await statusStream.firstWhere(
        (s) => s.isReady || s.isFailed,
        orElse: () => const MediaAssetStatusResponse(status: 'processing'),
      );
      return status;
    } catch (_) {
      return const MediaAssetStatusResponse(status: 'processing');
    }
  }

  /// Fetch all previously uploaded KYC documents for the owner
  Future<FetchKycDocumentsResponse> fetchAllKycDocuments() async {
    return _mediaApi.fetchAllKycDocuments();
  }
}
