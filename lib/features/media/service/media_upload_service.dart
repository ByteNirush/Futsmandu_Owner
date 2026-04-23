import 'dart:async';

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
      onStatusMessage?.call('Processing image…');
      status = await _pollUntilReady(
        assetId: confirm.assetId!,
        onStatusMessage: onStatusMessage,
      );
    }

    final isReady = status.isReady;
    onStatusMessage?.call(
      isReady ? 'SUCCESS: Image ready.' : 'Upload complete.',
    );

    // Prefer processed WebP URL; fall back to presign-step CDN URL.
    final bestUrl = status.webpUrl ?? uploadUrlResponse.cdnUrl;

    final result = MediaUploadResult(
      key: uploadUrlResponse.key,
      cdnUrl: uploadUrlResponse.cdnUrl,
      webpUrl: status.webpUrl,
      thumbUrl: status.thumbUrl,
      confirmMessage: confirm.message,
      assetId: confirm.assetId,
      status: status,
    );

    // Update cache with the best available URL after processing.
    if (confirm.assetId != null) {
      uploadedImageCache.save(
        assetId: confirm.assetId!,
        key: uploadUrlResponse.key,
        cdnUrl: bestUrl,
        webpUrl: status.webpUrl,
        thumbUrl: status.thumbUrl,
        imageBytes: bytes,
      );
    }

    return result;
  }

  // ── Polling helper ──────────────────────────────────────────────────────

  /// Drives the poller until status is terminal (ready / failed / timeout).
  ///
  /// Safety net: a 6-minute [Future.timeout] wraps the stream subscription so
  /// the call *always* returns even if the poller loop stalls unexpectedly.
  Future<MediaAssetStatusResponse> _pollUntilReady({
    required String assetId,
    void Function(String message)? onStatusMessage,
  }) async {
    final completer = Completer<MediaAssetStatusResponse>();
    StreamSubscription<MediaAssetStatusResponse>? sub;

    void complete(MediaAssetStatusResponse s) {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.complete(s);
      }
    }

    sub = _statusPoller.pollStatus(assetId).listen(
      (status) {
        // Forward intermediate progress messages to the UI.
        if (status.isProcessing) {
          final pct = status.progress;
          onStatusMessage?.call(
            pct != null
                ? 'Processing\u2026 $pct%'
                : 'Processing\u2026',
          );
        }

        // Resolve on any terminal status.
        if (status.isReady || status.isFailed) {
          complete(status);
        } else if (status.status == 'timeout') {
          // Poller hit its hard cap; surface gracefully.
          complete(const MediaAssetStatusResponse(status: 'processing'));
        }
      },
      onError: (_) {
        // Stream error should not surface to the UI as a crash.
        if (!completer.isCompleted) {
          complete(const MediaAssetStatusResponse(status: 'processing'));
        }
      },
      onDone: () {
        // Stream closed before a terminal event — treat as processing.
        if (!completer.isCompleted) {
          complete(const MediaAssetStatusResponse(status: 'processing'));
        }
      },
      cancelOnError: false,
    );

    // Absolute safety net: if nothing resolves in 6 min, unblock the caller.
    return completer.future.timeout(
      const Duration(minutes: 6),
      onTimeout: () {
        sub?.cancel();
        _statusPoller.cancel(assetId);
        return const MediaAssetStatusResponse(status: 'processing');
      },
    );
  }

  /// Fetch all previously uploaded KYC documents for the owner
  Future<FetchKycDocumentsResponse> fetchAllKycDocuments() async {
    return _mediaApi.fetchAllKycDocuments();
  }
}
