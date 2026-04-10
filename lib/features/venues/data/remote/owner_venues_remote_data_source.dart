import '../../../../core/config/owner_api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../domain/models/venue_models.dart';

class OwnerVenuesRemoteDataSource {
  OwnerVenuesRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final ApiClient _apiClient;

  Future<List<Venue>> listVenues() async {
    final response = await _apiClient.get(OwnerApiConfig.venuesEndpoint);
    return _asVenueList(response);
  }

  Future<Venue> createVenue(VenueUpsertRequest request) async {
    final response = await _apiClient.post(
      OwnerApiConfig.venuesEndpoint,
      data: request.toJson(),
    );
    return Venue.fromJson(_asMap(response));
  }

  Future<Venue> updateVenue({
    required String venueId,
    required VenueUpsertRequest request,
  }) async {
    final response = await _apiClient.put(
      OwnerApiConfig.ownerVenueEndpoint(venueId),
      data: request.toUpdateJson(),
    );
    return Venue.fromJson(_asMap(response));
  }

  Future<VenueImageUploadRequest> requestVenueImageUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  }) async {
    if (fileName.trim().isEmpty) {
      throw ApiException('Image file name is required.');
    }
    if (contentType.trim().isEmpty) {
      throw ApiException('Image content type is required.');
    }
    if (contentLength != null && contentLength < 0) {
      throw ApiException('Image content length must be non-negative.');
    }

    final response = await _apiClient.post(
      OwnerApiConfig.venueCoverUploadUrlEndpoint(venueId),
    );
    final payload = _asMap(response);
    final upload = VenueImageUploadRequest.fromJson(payload);
    if (upload.uploadUrl.isEmpty) {
      throw ApiException('Invalid upload URL response from server.');
    }
    return upload;
  }

  Future<VenueImageUploadConfirmation> confirmVenueImageUploadDetailed({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) async {
    final fileKey = upload.key ?? '';
    if (fileKey.isEmpty) {
      throw ApiException('Missing upload key from presign response.');
    }

    final response = await _apiClient.post(
      OwnerApiConfig.mediaConfirmUploadEndpoint,
      data: {'key': fileKey, 'assetType': 'venue_cover'},
    );
    final mapped = _asMap(response);
    return VenueImageUploadConfirmation.fromJson(mapped);
  }

  Future<VenueImageUploadStatus> pollVenueImageUploadStatus({
    required String assetId,
  }) async {
    final response = await _apiClient.get(
      OwnerApiConfig.mediaStatusEndpoint(assetId),
    );
    return VenueImageUploadStatus.fromJson(_asMap(response));
  }

  Map<String, dynamic> _asMap(Map<String, dynamic> response) {
    if (response['value'] is Map<String, dynamic>) {
      return response['value'] as Map<String, dynamic>;
    }
    if (response['item'] is Map<String, dynamic>) {
      return response['item'] as Map<String, dynamic>;
    }
    if (response['venue'] is Map<String, dynamic>) {
      return response['venue'] as Map<String, dynamic>;
    }
    if (response['data'] is Map<String, dynamic>) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  List<Venue> _asVenueList(Map<String, dynamic> response) {
    final rawItems =
        response['items'] ??
        response['venues'] ??
        response['data'] ??
        response['value'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(Venue.fromJson)
        .toList(growable: false);
  }
}
