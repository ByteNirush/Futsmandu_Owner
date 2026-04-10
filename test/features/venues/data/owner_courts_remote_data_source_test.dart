import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:futsmandu/core/network/api_client.dart';
import 'package:futsmandu/features/venues/data/remote/owner_courts_remote_data_source.dart';
import 'package:futsmandu/features/venues/domain/models/court_models.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  Map<String, dynamic> nextGetResponse = <String, dynamic>{};
  Map<String, dynamic> nextPostResponse = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return nextGetResponse;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    bool requiresAuth = true,
  }) async {
    return nextPostResponse;
  }
}

CourtUpsertRequest buildCourtRequest() {
  return const CourtUpsertRequest(
    name: 'Court Alpha',
    courtType: '5v5',
    surface: 'Artificial Grass',
    capacity: 12,
    minPlayers: 4,
    slotDurationMins: 60,
    openTime: '06:00',
    closeTime: '22:00',
  );
}

void main() {
  test('listCourts injects venue_id when backend omits it', () async {
    final apiClient = FakeApiClient()
      ..nextGetResponse = {
        'items': [
          {
            'id': 'court-1',
            'name': 'Court Alpha',
            'court_type': '5v5',
            'surface': 'Artificial Grass',
            'capacity': 12,
            'min_players': 4,
            'slot_duration_mins': 60,
            'open_time': '06:00',
            'close_time': '22:00',
          },
        ],
      };

    final dataSource = OwnerCourtsRemoteDataSource(apiClient: apiClient);
    final courts = await dataSource.listCourts('venue-123');

    expect(courts, hasLength(1));
    expect(courts.first.id, 'court-1');
    expect(courts.first.venueId, 'venue-123');
  });

  test('createCourt injects venue_id when backend omits it', () async {
    final apiClient = FakeApiClient()
      ..nextPostResponse = {
        'id': 'court-2',
        'name': 'Court Alpha',
        'court_type': '5v5',
        'slot_duration_mins': 60,
        'created_at': '2026-01-01T00:00:00.000Z',
      };

    final dataSource = OwnerCourtsRemoteDataSource(apiClient: apiClient);
    final court = await dataSource.createCourt(
      venueId: 'venue-abc',
      request: buildCourtRequest(),
    );

    expect(court.id, 'court-2');
    expect(court.venueId, 'venue-abc');
    expect(court.slotDurationMins, 60);
  });
}
