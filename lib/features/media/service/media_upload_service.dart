import '../model/media_upload_models.dart';
import 'owner_media_api.dart';

class MediaUploadService {
  MediaUploadService({
    OwnerMediaApi? mediaApi,
    OwnerMediaStorageUploader? storageUploader,
  }) : _mediaApi = mediaApi ?? OwnerMediaApi(),
       _storageUploader = storageUploader ?? OwnerMediaStorageUploader();

  final OwnerMediaApi _mediaApi;
  final OwnerMediaStorageUploader _storageUploader;

  Future<MediaUploadResult> uploadAndConfirm({
    required OwnerMediaAssetType assetType,
    required String entityId,
    required List<int> bytes,
    required String contentType,
    OwnerKycDocType? docType,
    bool pollUntilReady = false,
    void Function(String message)? onStatusMessage,
    void Function(double progress)? onUploadProgress,
  }) async {
    onStatusMessage?.call('Requesting upload URL...');
    final uploadUrlResponse = assetType == OwnerMediaAssetType.venueCover
        ? await _mediaApi.requestVenueCoverUploadUrl(venueId: entityId)
        : await _mediaApi.requestUploadUrl(
            MediaUploadUrlRequest(
              assetType: assetType,
              entityId: entityId,
              docType: docType,
              contentType: contentType,
            ),
          );

    onStatusMessage?.call('Uploading image...');
    await _storageUploader.uploadBytes(
      uploadUrl: uploadUrlResponse.uploadUrl,
      bytes: bytes,
      contentType: contentType,
      headers: uploadUrlResponse.headers,
      onProgress: onUploadProgress,
    );

    onStatusMessage?.call('Confirming upload...');
    final confirm = await _mediaApi.confirmUpload(
      MediaConfirmUploadRequest(
        key: uploadUrlResponse.key,
        assetType: assetType,
      ),
    );

    var status = MediaAssetStatusResponse(
      status: confirm.status ?? 'processing',
    );

    if (pollUntilReady && confirm.assetId != null) {
      onStatusMessage?.call('Waiting for image processing...');
      status = await _pollUntilReady(confirm.assetId!);
    }

    onStatusMessage?.call(
      status.isReady ? 'Image is ready.' : 'Image upload completed.',
    );

    return MediaUploadResult(
      key: uploadUrlResponse.key,
      cdnUrl: uploadUrlResponse.cdnUrl,
      confirmMessage: confirm.message,
      assetId: confirm.assetId,
      status: status,
    );
  }

  Future<MediaAssetStatusResponse> _pollUntilReady(String assetId) async {
    const maxAttempts = 30;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final status = await _mediaApi.getUploadStatus(assetId);
      if (status.isReady || status.isFailed) {
        return status;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    return const MediaAssetStatusResponse(status: 'processing');
  }
}
