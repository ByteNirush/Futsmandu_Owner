import '../models/venue_models.dart';
import '../repositories/venues_repository.dart';

class ListVenuesUseCase {
  const ListVenuesUseCase(this._repository);

  final VenuesRepository _repository;

  Future<List<Venue>> call() => _repository.listVenues();
}
