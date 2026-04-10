import '../models/venue_models.dart';
import '../repositories/venues_repository.dart';

class UpsertVenueUseCase {
  const UpsertVenueUseCase(this._repository);

  final VenuesRepository _repository;

  Future<Venue> create(VenueUpsertRequest request) =>
      _repository.createVenue(request);

  Future<Venue> update({
    required String venueId,
    required VenueUpsertRequest request,
  }) => _repository.updateVenue(venueId: venueId, request: request);
}
