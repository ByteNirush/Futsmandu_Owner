import 'package:dio/dio.dart';

import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';
import '../model/media_upload_models.dart';

class OwnerMediaApi {
  OwnerMediaApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<MediaUploadUrlResponse> requestUploadUrl(
    MediaUploadUrlRequest request,
  ) async {
    final response = await _apiClient.post(
      OwnerApiConfig.mediaUploadUrlEndpoint,
      data: request.toJson(),
    );
    final parsed = MediaUploadUrlResponse.fromJson(response);
    if (parsed.uploadUrl.isEmpty || parsed.key.isEmpty) {
      throw ApiException('Invalid media upload URL response from server.');
    }
    return parsed;
  }

  Future<MediaUploadUrlResponse> requestVenueCoverUploadUrl({
    required String venueId,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.venueCoverUploadUrlEndpoint(venueId),
    );
    final parsed = MediaUploadUrlResponse.fromJson(response);
    if (parsed.uploadUrl.isEmpty || parsed.key.isEmpty) {
      throw ApiException('Invalid venue cover upload URL response from server.');
    }
    return parsed;
  }

  Future<MediaConfirmUploadResponse> confirmUpload(
    MediaConfirmUploadRequest request,
  ) async {
    final response = await _apiClient.post(
      OwnerApiConfig.mediaConfirmUploadEndpoint,
      data: request.toJson(),
    );
    return MediaConfirmUploadResponse.fromJson(response);
  }

  Future<MediaAssetStatusResponse> getUploadStatus(String assetId) async {
    final response = await _apiClient.get(
      OwnerApiConfig.mediaStatusEndpoint(assetId),
    );
    return MediaAssetStatusResponse.fromJson(response);
  }
}

class OwnerMediaStorageUploader {
  OwnerMediaStorageUploader({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _dio;

  Future<void> uploadBytes({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Map<String, String> headers = const <String, String>{},
    void Function(double progress)? onProgress,
  }) async {
    await _dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          ...headers,
          if (!headers.keys.any((key) => key.toLowerCase() == 'content-type'))
            'Content-Type': contentType,
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
}
