import '../models/court_models.dart';
import '../models/venue_models.dart';

abstract class VenuesRepository {
  Future<List<Venue>> listVenues();

  Future<Venue> createVenue(VenueUpsertRequest request);

  Future<Venue> updateVenue({required String venueId, required VenueUpsertRequest request});

  Future<List<Court>> listCourts(String venueId);

  Future<Court> createCourt({required String venueId, required CourtUpsertRequest request});

  Future<Court> updateCourt({required String courtId, required CourtUpsertRequest request});

  Future<void> deleteCourt(String courtId);

  Future<VenueImageUploadRequest> requestVenueImageUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  });

  Future<void> uploadVenueImageToStorage({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double progress)? onProgress,
  });

  Future<String?> confirmVenueImageUpload({
    required String venueId,
    required VenueImageUploadRequest upload,
  });
}
