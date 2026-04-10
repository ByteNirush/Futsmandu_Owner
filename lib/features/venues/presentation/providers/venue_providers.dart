import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/venues_repository_impl.dart';
import '../../domain/models/court_models.dart';
import '../../domain/models/venue_models.dart';
import '../../domain/repositories/venues_repository.dart';
import '../../domain/usecases/list_venues_usecase.dart';
import '../../domain/usecases/manage_courts_usecase.dart';
import '../../domain/usecases/upsert_venue_usecase.dart';

final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  return VenuesRepositoryImpl();
});

final listVenuesUseCaseProvider = Provider<ListVenuesUseCase>((ref) {
  return ListVenuesUseCase(ref.read(venuesRepositoryProvider));
});

final upsertVenueUseCaseProvider = Provider<UpsertVenueUseCase>((ref) {
  return UpsertVenueUseCase(ref.read(venuesRepositoryProvider));
});

final manageCourtsUseCaseProvider = Provider<ManageCourtsUseCase>((ref) {
  return ManageCourtsUseCase(ref.read(venuesRepositoryProvider));
});

final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  final useCase = ref.read(listVenuesUseCaseProvider);
  final venues = await useCase();
  return venues.where((venue) => venue.isActive).toList(growable: false);
});

final venueCourtsProvider =
    FutureProvider.family<List<Court>, String>((ref, venueId) async {
  final useCase = ref.read(manageCourtsUseCaseProvider);
  final courts = await useCase.list(venueId);
  return courts.where((court) => court.isActive).toList(growable: false);
});
