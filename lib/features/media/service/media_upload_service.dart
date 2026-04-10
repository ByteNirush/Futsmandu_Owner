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
    void Function(double progress)? onUploadProgress,
  }) async {
    final uploadUrlResponse = await _mediaApi.requestUploadUrl(
      MediaUploadUrlRequest(
        assetType: assetType,
        entityId: entityId,
        docType: docType,
        contentType: contentType,
      ),
    );

    await _storageUploader.uploadBytes(
      uploadUrl: uploadUrlResponse.uploadUrl,
      bytes: bytes,
      contentType: contentType,
      headers: uploadUrlResponse.headers,
      onProgress: onUploadProgress,
    );

    final confirm = await _mediaApi.confirmUpload(
      MediaConfirmUploadRequest(
        key: uploadUrlResponse.key,
        assetType: assetType,
      ),
    );

    return MediaUploadResult(
      key: uploadUrlResponse.key,
      cdnUrl: uploadUrlResponse.cdnUrl,
      confirmMessage: confirm.message,
    );
  }
}
