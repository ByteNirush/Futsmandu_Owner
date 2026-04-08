import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';

class OwnerCourtsApi {
  OwnerCourtsApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<List<OwnerCourtOption>> listOwnerCourts() async {
    final venuesResponse = await _apiClient.get(OwnerApiConfig.venuesEndpoint);
    final venues = _asJsonList(venuesResponse['items']);

    final courts = <OwnerCourtOption>[];
    for (final venue in venues) {
      final venueId = venue['id'];
      if (venueId is! String || venueId.isEmpty) {
        continue;
      }

      final courtsResponse = await _apiClient.get(
        '${OwnerApiConfig.venuesEndpoint}/$venueId/courts',
      );
      final venueCourts = _asJsonList(courtsResponse['items']);

      for (final court in venueCourts) {
        final id = court['id'];
        final name = court['name'];
        if (id is String && id.isNotEmpty && name is String && name.isNotEmpty) {
          courts.add(OwnerCourtOption(id: id, name: name));
        }
      }
    }

    final deduped = <String, OwnerCourtOption>{};
    for (final court in courts) {
      deduped[court.id] = court;
    }
    return deduped.values.toList(growable: false);
  }

  List<Map<String, dynamic>> _asJsonList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

class OwnerCourtOption {
  OwnerCourtOption({required this.id, required this.name});

  final String id;
  final String name;
}
