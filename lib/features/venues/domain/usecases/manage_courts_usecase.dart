import '../models/court_models.dart';
import '../repositories/venues_repository.dart';

class ManageCourtsUseCase {
  const ManageCourtsUseCase(this._repository);

  final VenuesRepository _repository;

  Future<List<Court>> list(String venueId) => _repository.listCourts(venueId);

  Future<Court> create({
    required String venueId,
    required CourtUpsertRequest request,
  }) => _repository.createCourt(venueId: venueId, request: request);

  Future<Court> update({
    required String courtId,
    required CourtUpsertRequest request,
  }) => _repository.updateCourt(courtId: courtId, request: request);

  Future<void> delete(String courtId) => _repository.deleteCourt(courtId);
}
