import '../../../core/errors/app_failure.dart';
import '../../media/model/media_upload_models.dart';
import '../../media/service/media_upload_service.dart';
import '../domain/models/venue_models.dart';

// ============================================================================
// VenueImageUploadService
// Thin wrapper around MediaUploadService that speaks Venue domain types.
// Uses the correct per-type endpoint for each asset (cover vs gallery vs
// verification) instead of the old generic /upload-url route.
// ============================================================================

abstract class VenueImageUploadService {
  Future<VenueImageUploadResult> uploadVenueCoverImage({
    required String venueId,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady,
  });

  Future<VenueImageUploadResult> uploadVenueGalleryImage({
    required String venueId,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady,
  });

  Future<VenueImageUploadResult> uploadVenueVerificationDocument({
    required String venueId,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady,
  });
}

class OwnerVenueImageUploadService implements VenueImageUploadService {
  OwnerVenueImageUploadService({MediaUploadService? mediaUploadService})
      : _mediaUploadService = mediaUploadService ?? MediaUploadService();

  final MediaUploadService _mediaUploadService;

  @override
  Future<VenueImageUploadResult> uploadVenueCoverImage({
    required String venueId,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady = true,
  }) {
    return _wrap(
      () => _mediaUploadService.uploadVenueCover(
        venueId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onUploadProgress: onProgress,
        onStatusMessage: onStatusMessage,
      ),
    );
  }

  @override
  Future<VenueImageUploadResult> uploadVenueGalleryImage({
    required String venueId,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady = true,
  }) {
    return _wrap(
      () => _mediaUploadService.uploadVenueGalleryImage(
        venueId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onUploadProgress: onProgress,
        onStatusMessage: onStatusMessage,
      ),
    );
  }

  @override
  Future<VenueImageUploadResult> uploadVenueVerificationDocument({
    required String venueId,
    required String contentType,
    required List<int> bytes,
    void Function(double progress)? onProgress,
    void Function(String message)? onStatusMessage,
    bool pollUntilReady = false,
  }) {
    return _wrap(
      () => _mediaUploadService.uploadVenueVerification(
        venueId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onUploadProgress: onProgress,
        onStatusMessage: onStatusMessage,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Map MediaUploadResult → VenueImageUploadResult
  // --------------------------------------------------------------------------

  Future<VenueImageUploadResult> _wrap(
    Future<MediaUploadResult> Function() task,
  ) async {
    try {
      final result = await task();
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
