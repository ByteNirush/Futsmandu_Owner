import '../../../core/errors/app_failure.dart';
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
}

class OwnerVenueImageUploadService implements VenueImageUploadService {
  OwnerVenueImageUploadService({VenuesRepository? repository})
    : _repository = repository ?? VenuesRepositoryImpl();

  final VenuesRepository _repository;

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
}
