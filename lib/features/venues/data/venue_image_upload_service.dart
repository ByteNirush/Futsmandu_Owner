import '../../../core/errors/app_failure.dart';
import '../../media/model/media_upload_models.dart';
import '../../media/service/media_upload_service.dart';
import '../domain/models/venue_models.dart';
import '../domain/repositories/venues_repository.dart';
import 'repositories/venues_repository_impl.dart';

abstract class VenueImageUploadService {
  Future<VenueImageUploadRequest> requestUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  });

  Future<void> uploadBytesWithRetry({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    int maxRetries,
  });

  Future<String?> confirmUpload({
    required String venueId,
    required VenueImageUploadRequest upload,
  });

  Future<VenueImageUploadResult> uploadVenueCoverImage({
    required String venueId,
    required String fileName,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady,
  });
}

class OwnerVenueImageUploadService implements VenueImageUploadService {
  OwnerVenueImageUploadService({VenuesRepository? repository})
    : _repository = repository ?? VenuesRepositoryImpl(),
      _mediaUploadService = MediaUploadService();

  final VenuesRepository _repository;
  final MediaUploadService _mediaUploadService;

  @override
  Future<VenueImageUploadRequest> requestUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  }) {
    return _repository.requestVenueImageUploadUrl(
      venueId: venueId,
      fileName: fileName,
      contentType: contentType,
      contentLength: contentLength,
    );
  }

  @override
  Future<void> uploadBytesWithRetry({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    int maxRetries = 2,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await _repository.uploadVenueImageToStorage(
          upload: upload,
          bytes: bytes,
          onProgress: onProgress,
        );
        return;
      } catch (error) {
        lastError = error;
      }
    }
    throw AppFailure(
      'Image upload failed after retries: ${lastError ?? 'unknown error'}',
    );
  }

  @override
  Future<String?> confirmUpload({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) {
    return _repository.confirmVenueImageUpload(
      venueId: venueId,
      upload: upload,
    );
  }

  @override
  Future<VenueImageUploadResult> uploadVenueCoverImage({
    required String venueId,
    required String fileName,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady = true,
  }) async {
    try {
      final result = await _mediaUploadService.uploadAndConfirm(
        assetType: OwnerMediaAssetType.venueCover,
        entityId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onUploadProgress: onProgress,
        onStatusMessage: onStatusMessage,
      );

      return VenueImageUploadResult(
        upload: VenueImageUploadRequest(
          uploadUrl: '',
          method: 'PUT',
          headers: const <String, String>{},
          expiresIn: 0,
          key: result.key,
          assetId: result.assetId,
          publicUrl: result.cdnUrl,
        ),
        confirmation: VenueImageUploadConfirmation(
          message: result.confirmMessage,
          assetId: result.assetId,
          status: result.status.status,
        ),
        status: VenueImageUploadStatus(status: result.status.status),
        cdnUrl: result.cdnUrl,
      );
    } catch (error) {
      throw AppFailure(
        'Image upload failed: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}
