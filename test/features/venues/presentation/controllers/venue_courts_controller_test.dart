import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:futsmandu/features/venues/domain/models/court_models.dart';
import 'package:futsmandu/features/venues/domain/models/venue_models.dart';
import 'package:futsmandu/features/venues/domain/repositories/venues_repository.dart';
import 'package:futsmandu/features/venues/presentation/controllers/venue_courts_controller.dart';

class FakeCourtsRepository implements VenuesRepository {
  FakeCourtsRepository({this.shouldThrow = false});

  final bool shouldThrow;
  List<Court> courts = const [];
  String? deletedCourtId;

  @override
  Future<Court> createCourt({
    required String venueId,
    required CourtUpsertRequest request,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Venue> createVenue(VenueUpsertRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCourt(String courtId) async {
    if (shouldThrow) {
      throw StateError('delete failed');
    }
    deletedCourtId = courtId;
  }

  @override
  Future<List<Court>> listCourts(String venueId) async {
    if (shouldThrow) {
      throw StateError('load failed');
    }
    return courts
        .where((court) => court.venueId == venueId)
        .toList(growable: false);
  }

  @override
  Future<List<Venue>> listVenues() async {
    throw UnimplementedError();
  }

  @override
  Future<Venue> updateVenue({
    required String venueId,
    required VenueUpsertRequest request,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Court> updateCourt({
    required String courtId,
    required CourtUpsertRequest request,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> confirmVenueImageUpload({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<VenueImageUploadConfirmation> confirmVenueImageUploadDetailed({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<VenueImageUploadStatus> pollVenueImageUploadStatus({
    required String assetId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<VenueImageUploadRequest> requestVenueImageUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadVenueImageToStorage({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double p1)? onProgress,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('VenueCourtsController loads courts for a venue', () async {
    final repository = FakeCourtsRepository()
      ..courts = [
        const Court(
          id: 'court-1',
          venueId: 'venue-1',
          name: 'Court A',
          courtType: 'Indoor',
          surface: 'Artificial Turf',
          capacity: 12,
          minPlayers: 4,
          slotDurationMins: 60,
          openTime: '06:00',
          closeTime: '22:00',
        ),
      ];

    final controller = VenueCourtsController(repository: repository);
    await controller.loadCourts('venue-1');

    expect(controller.state.name, 'content');
    expect(controller.courts, hasLength(1));
    expect(controller.errorMessage, isNull);
  });

  test('VenueCourtsController surfaces load errors', () async {
    final controller = VenueCourtsController(
      repository: FakeCourtsRepository(shouldThrow: true),
    );

    await controller.loadCourts('venue-1');

    expect(controller.state.name, 'error');
    expect(controller.errorMessage, contains('load failed'));
  });
}
