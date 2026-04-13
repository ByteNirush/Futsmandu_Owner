import 'package:dio/dio.dart';

import '../../../../core/network/debug_dio_logging_interceptor.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../domain/models/court_models.dart';
import '../../domain/models/venue_models.dart';
import '../../domain/repositories/venues_repository.dart';
import '../remote/owner_courts_remote_data_source.dart';
import '../remote/owner_venues_remote_data_source.dart';

class VenuesRepositoryImpl implements VenuesRepository {
  VenuesRepositoryImpl({
    OwnerVenuesRemoteDataSource? venuesDataSource,
    OwnerCourtsRemoteDataSource? courtsDataSource,
  }) : _venuesDataSource =
           venuesDataSource ??
           OwnerVenuesRemoteDataSource(apiClient: OwnerApiClient()),
       _courtsDataSource =
           courtsDataSource ??
           OwnerCourtsRemoteDataSource(apiClient: OwnerApiClient()),
       _storageUploadClient = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 60),
           sendTimeout: const Duration(seconds: 60),
         ),
       )..interceptors.add(DebugDioLoggingInterceptor());

  final OwnerVenuesRemoteDataSource _venuesDataSource;
  final OwnerCourtsRemoteDataSource _courtsDataSource;
  final Dio _storageUploadClient;

  @override
  Future<List<Venue>> listVenues() => _venuesDataSource.listVenues();

  @override
  Future<Venue> createVenue(VenueUpsertRequest request) =>
      _venuesDataSource.createVenue(request);

  @override
  Future<Venue> updateVenue({
    required String venueId,
    required VenueUpsertRequest request,
  }) => _venuesDataSource.updateVenue(venueId: venueId, request: request);

  @override
  Future<List<Court>> listCourts(String venueId) =>
      _courtsDataSource.listCourts(venueId);

  @override
  Future<Court> createCourt({
    required String venueId,
    required CourtUpsertRequest request,
  }) => _courtsDataSource.createCourt(venueId: venueId, request: request);

  @override
  Future<Court> updateCourt({
    required String courtId,
    required CourtUpsertRequest request,
  }) => _courtsDataSource.updateCourt(courtId: courtId, request: request);

  @override
  Future<void> deleteCourt(String courtId) =>
      _courtsDataSource.deleteCourt(courtId: courtId);

  @override
  Future<VenueImageUploadRequest> requestVenueImageUploadUrl({
    required String venueId,
    required String fileName,
    required String contentType,
    int? contentLength,
  }) {
    return _venuesDataSource.requestVenueImageUploadUrl(
      venueId: venueId,
      fileName: fileName,
      contentType: contentType,
      contentLength: contentLength,
    );
  }

  @override
  Future<void> uploadVenueImageToStorage({
    required VenueImageUploadRequest upload,
    required List<int> bytes,
    void Function(double progress)? onProgress,
  }) async {
    await _storageUploadClient.request<void>(
      upload.uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        method: upload.method,
        headers: {
          ...upload.headers,
          if (!upload.headers.keys.any(
            (key) => key.toLowerCase() == 'content-type',
          ))
            'Content-Type': 'application/octet-stream',
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress == null || total <= 0) {
          return;
        }
        onProgress(sent / total);
      },
    );
  }

  @override
  Future<String?> confirmVenueImageUpload({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) {
    return _venuesDataSource.confirmVenueImageUploadDetailed(
      venueId: venueId,
      upload: upload,
    ).then((confirmation) => upload.resolvedImageUrl ?? confirmation.assetId);
  }

  @override
  Future<VenueImageUploadConfirmation> confirmVenueImageUploadDetailed({
    required String venueId,
    required VenueImageUploadRequest upload,
  }) {
    return _venuesDataSource.confirmVenueImageUploadDetailed(
      venueId: venueId,
      upload: upload,
    );
  }

  @override
  Future<VenueImageUploadStatus> pollVenueImageUploadStatus({
    required String assetId,
  }) {
    return _venuesDataSource.pollVenueImageUploadStatus(assetId: assetId);
  }
}
