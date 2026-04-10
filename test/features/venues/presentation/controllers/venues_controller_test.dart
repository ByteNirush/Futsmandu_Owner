import 'package:flutter_test/flutter_test.dart';

import 'package:futsmandu/features/venues/domain/models/court_models.dart';
import 'package:futsmandu/features/venues/domain/models/venue_models.dart';
import 'package:futsmandu/features/venues/domain/repositories/venues_repository.dart';
import 'package:futsmandu/features/venues/presentation/controllers/venue_form_controller.dart';
import 'package:futsmandu/features/venues/presentation/controllers/venues_list_controller.dart';

class FakeVenuesRepository implements VenuesRepository {
  FakeVenuesRepository({this.shouldThrow = false});

  final bool shouldThrow;
  List<Venue> venues = const [];
  List<Court> courts = const [];
  Venue? createdVenue;
  Venue? updatedVenue;
  Court? createdCourt;
  Court? updatedCourt;
  String? deletedCourtId;

  @override
  Future<Venue> createVenue(VenueUpsertRequest request) async {
    if (shouldThrow) {
      throw StateError('create failed');
    }
    createdVenue = Venue(
      id: 'venue-new',
      name: request.name,
      description: request.description,
      address: request.address,
      latitude: request.latitude,
      longitude: request.longitude,
      amenities: request.amenities,
      fullRefundHours: request.fullRefundHours,
      partialRefundHours: request.partialRefundHours,
      partialRefundPct: request.partialRefundPct,
    );
    return createdVenue!;
  }

  @override
  Future<Court> createCourt({
    required String venueId,
    required CourtUpsertRequest request,
  }) async {
    if (shouldThrow) {
      throw StateError('create court failed');
    }
    createdCourt = Court(
      id: 'court-new',
      venueId: venueId,
      name: request.name,
      courtType: request.courtType,
      surface: request.surface,
      capacity: request.capacity,
      minPlayers: request.minPlayers,
      slotDurationMins: request.slotDurationMins,
      openTime: request.openTime,
      closeTime: request.closeTime,
    );
    return createdCourt!;
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
      throw StateError('load courts failed');
    }
    return courts
        .where((court) => court.venueId == venueId)
        .toList(growable: false);
  }

  @override
  Future<List<Venue>> listVenues() async {
    if (shouldThrow) {
      throw StateError('load failed');
    }
    return venues;
  }

  @override
  Future<Venue> updateVenue({
    required String venueId,
    required VenueUpsertRequest request,
  }) async {
    if (shouldThrow) {
      throw StateError('update failed');
    }
    updatedVenue = Venue(
      id: venueId,
      name: request.name,
      description: request.description,
      address: request.address,
      latitude: request.latitude,
      longitude: request.longitude,
      amenities: request.amenities,
      fullRefundHours: request.fullRefundHours,
      partialRefundHours: request.partialRefundHours,
      partialRefundPct: request.partialRefundPct,
    );
    return updatedVenue!;
  }

  @override
  Future<Court> updateCourt({
    required String courtId,
    required CourtUpsertRequest request,
  }) async {
    if (shouldThrow) {
      throw StateError('update court failed');
    }
    updatedCourt = Court(
      id: courtId,
      venueId: 'venue-1',
      name: request.name,
      courtType: request.courtType,
      surface: request.surface,
      capacity: request.capacity,
      minPlayers: request.minPlayers,
      slotDurationMins: request.slotDurationMins,
      openTime: request.openTime,
      closeTime: request.closeTime,
    );
    return updatedCourt!;
  }

  @override
  Future<String?> confirmVenueImageUpload({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) async {
    if (shouldThrow) {
      throw StateError('confirm image failed');
    }
    return upload.resolvedImageUrl;
  }

  @override
  Future<VenueImageUploadConfirmation> confirmVenueImageUploadDetailed({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) async {
    if (shouldThrow) {
      throw StateError('confirm image failed');
    }
    return VenueImageUploadConfirmation(
      message: 'Upload confirmed.',
      assetId: upload.assetId,
      status: 'ready',
    );
  }

  @override
  Future<VenueImageUploadStatus> pollVenueImageUploadStatus({
    required String assetId,
  }) async {
    if (shouldThrow) {
      throw StateError('poll image status failed');
    }
    return const VenueImageUploadStatus(status: 'ready');
  }

  @override
  Future<VenueImageUploadRequest> requestVenueImageUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  }) async {
    if (shouldThrow) {
      throw StateError('upload url failed');
    }
    return const VenueImageUploadRequest(
      uploadUrl: 'https://example.com/upload',
      method: 'PUT',
      headers: <String, String>{},
      expiresIn: 600,
      imageUrl: 'https://cdn.example.com/image.jpg',
    );
  }

  @override
  Future<void> uploadVenueImageToStorage({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double p1)? onProgress,
  }) async {
    if (shouldThrow) {
      throw StateError('upload image failed');
    }
    onProgress?.call(1);
  }
}

void main() {
  test('VenuesListController loads and exposes content state', () async {
    final repository = FakeVenuesRepository(shouldThrow: false)
      ..venues = [
        Venue(
          id: 'venue-1',
          name: 'Arena One',
          description: 'Main venue',
          address: const VenueAddress(
            street: 'Street 1',
            city: 'Kathmandu',
            district: 'Kathmandu',
          ),
          latitude: 27.7172,
          longitude: 85.324,
          amenities: const ['Parking'],
          fullRefundHours: 24,
          partialRefundHours: 12,
          partialRefundPct: 50,
        ),
      ];

    final controller = VenuesListController(repository: repository);
    await controller.loadVenues();

    expect(controller.state.name, 'content');
    expect(controller.venues, hasLength(1));
    expect(controller.errorMessage, isNull);
  });

  test('VenuesListController surfaces errors from repository', () async {
    final controller = VenuesListController(
      repository: FakeVenuesRepository(shouldThrow: true),
    );

    await controller.loadVenues();

    expect(controller.state.name, 'error');
    expect(controller.errorMessage, contains('load failed'));
  });

  test('VenueFormController toggles submitting state during create', () async {
    final repository = FakeVenuesRepository();
    final controller = VenueFormController(repository: repository);
    final request = VenueUpsertRequest(
      name: 'Arena One',
      description: 'Main venue',
      address: const VenueAddress(
        street: 'Street 1',
        city: 'Kathmandu',
        district: 'Kathmandu',
      ),
      latitude: 27.7172,
      longitude: 85.324,
      amenities: const ['Parking'],
      fullRefundHours: 24,
      partialRefundHours: 12,
      partialRefundPct: 50,
    );

    final result = await controller.submit(
      mode: VenueFormMode.create,
      request: request,
    );

    expect(result?.id, 'venue-new');
    expect(controller.isSubmitting, isFalse);
    expect(repository.createdVenue?.name, 'Arena One');
  });
}
