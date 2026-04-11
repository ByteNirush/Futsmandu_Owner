import '../../../../core/config/owner_api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../domain/models/court_models.dart';

class OwnerCourtsRemoteDataSource {
  OwnerCourtsRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final ApiClient _apiClient;

  Future<List<Court>> listCourts(String venueId) async {
    final response = await _apiClient.get(
      OwnerApiConfig.venueCourtsEndpoint(venueId),
    );
    final rawItems =
        response['items'] ?? response['courts'] ?? response['data'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map((json) => Court.fromJson({
              ...json,
              if (!json.containsKey('venue_id') &&
                  !json.containsKey('venueId'))
                'venue_id': venueId,
            }))
        .toList(growable: false);
  }

  Future<Court> createCourt({
    required String venueId,
    required CourtUpsertRequest request,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.venueCourtsEndpoint(venueId),
      data: request.toJson(),
    );
    final mapped = _asMap(response);
    return Court.fromJson({
      ...mapped,
      if (!mapped.containsKey('venue_id') && !mapped.containsKey('venueId'))
        'venue_id': venueId,
    });
  }

  Future<Court> updateCourt({
    required String courtId,
    required CourtUpsertRequest request,
  }) async {
    final response = await _apiClient.put(
      OwnerApiConfig.courtEndpoint(courtId),
      data: request.toUpdateJson(),
    );
    return Court.fromJson(_asMap(response));
  }

  Future<void> deleteCourt({required String courtId}) async {
    await _apiClient.delete(OwnerApiConfig.courtEndpoint(courtId));
  }

  Map<String, dynamic> _asMap(Map<String, dynamic> response) {
    if (response['item'] is Map<String, dynamic>) {
      return response['item'] as Map<String, dynamic>;
    }
    return response;
  }
}
