import '../../../core/network/owner_api_client.dart';
import '../../media/model/media_upload_models.dart';

// ============================================================================
// KYC Documents Service
// Fetches KYC document metadata and download URLs from the API
// ============================================================================

class KycDocumentsService {
  KycDocumentsService({OwnerApiClient? apiClient})
      : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  /// Get download URL for a KYC document
  /// Used to display or download KYC documents
  Future<String> getKycDocumentDownloadUrl(String documentKey) async {
    final response = await _apiClient.post(
      '/api/v1/owner/media/download-url',
      data: MediaDownloadUrlRequest(key: documentKey).toJson(),
    );
    final downloadResponse = MediaDownloadUrlResponse.fromJson(response);
    return downloadResponse.downloadUrl;
  }

  /// Check if a KYC document exists and is ready to view
  Future<bool> isKycDocumentReady(String assetId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/owner/media/status/$assetId',
      );
      final status = MediaAssetStatusResponse.fromJson(response);
      return status.isReady;
    } catch (_) {
      return false;
    }
  }

  /// Get display URL (either CDN for public or signed download URL for private)
  /// For KYC documents (private), this fetches signed download URL
  Future<String?> getKycDocumentDisplayUrl(String documentKey) async {
    try {
      // KYC documents are private, need signed download URL
      return await getKycDocumentDownloadUrl(documentKey);
    } catch (_) {
      return null;
    }
  }

  /// Batch fetch multiple KYC document URLs
  Future<Map<String, String?>> getKycDocumentsUrls(
    List<String> documentKeys,
  ) async {
    final result = <String, String?>{};

    for (final key in documentKeys) {
      try {
        result[key] = await getKycDocumentDownloadUrl(key);
      } catch (_) {
        result[key] = null;
      }
    }

    return result;
  }
}
