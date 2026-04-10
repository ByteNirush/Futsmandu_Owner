import '../models/venue_models.dart';
import '../repositories/venues_repository.dart';

class UploadVenueImageUseCase {
  const UploadVenueImageUseCase(this._repository);

  final VenuesRepository _repository;

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

  Future<void> upload({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double progress)? onProgress,
  }) {
    return _repository.uploadVenueImageToStorage(
      upload: upload,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  Future<String?> confirm({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) {
    return _repository.confirmVenueImageUpload(venueId: venueId, upload: upload);
  }
}
