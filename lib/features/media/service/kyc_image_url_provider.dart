import 'package:flutter/foundation.dart';

import '../../auth/data/kyc_documents_service.dart';
import '../model/kyc_image_cache_model.dart';
import '../model/media_upload_models.dart';

// ============================================================================
// KycImageUrlProvider
// Manages KYC image URLs with expiry detection and refresh capabilities
// ============================================================================

class KycImageUrlProvider {
  KycImageUrlProvider({KycDocumentsService? kycService})
      : _kycService = kycService ?? KycDocumentsService();

  final KycDocumentsService _kycService;

  /// Cache of fetched URLs with their fetch time
  final Map<String, KycImageCacheEntry> _urlCache = {};

  /// Get cached KYC image URL or fetch fresh one if expired
  Future<String> getImageUrl(String docType) async {
    final cached = _urlCache[docType];

    // Return cached URL if still valid (with 2-minute safety margin)
    if (cached != null && !_isUrlExpired(cached.fetchedAt)) {
      return cached.downloadUrl;
    }

    // Fetch fresh URL from API
    return _fetchFreshUrl(docType);
  }

  /// Force refresh URL even if cached
  Future<String> refreshImageUrl(String docType) async {
    return _fetchFreshUrl(docType);
  }

  /// Check if URL is expired (considering 2-minute safety margin)
  bool _isUrlExpired(DateTime fetchedAt) {
    final expiryTime = fetchedAt.add(const Duration(minutes: 10));
    final safeMargin = expiryTime.subtract(const Duration(minutes: 2));
    return DateTime.now().isAfter(safeMargin);
  }

  /// Fetch URL from API and cache it
  Future<String> _fetchFreshUrl(String docType) async {
    try {
      // Fetch all KYC docs and select the requested docType.
      final response = await _kycService.getAllKycDocuments();
      KycDocumentItem? document;
      for (final doc in response.documents) {
        if (doc.docType == docType) {
          document = doc;
          break;
        }
      }

      if (document == null || document.downloadUrl.isEmpty) {
        throw StateError('No signed URL found for docType: $docType');
      }

      final downloadUrl = document.downloadUrl;

      // Cache the URL with fetch timestamp
      _urlCache[docType] = KycImageCacheEntry(
        downloadUrl: downloadUrl,
        fetchedAt: DateTime.now(),
      );

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Failed to fetch KYC URL for $docType: $e');
      rethrow;
    }
  }

  /// Clear cache for specific doc or all docs
  void clearCache({String? docType}) {
    if (docType != null) {
      _urlCache.remove(docType);
    } else {
      _urlCache.clear();
    }
  }

  /// Check if any URL is expiring soon
  bool isAnyUrlExpiringSoon() {
    return _urlCache.entries.any((entry) => _isUrlExpired(entry.value.fetchedAt));
  }

  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo(String docType) {
    final entry = _urlCache[docType];
    if (entry == null) return {'cached': false};

    return {
      'cached': true,
      'fetchedAt': entry.fetchedAt.toIso8601String(),
      'expiresAt': entry.fetchedAt
          .add(const Duration(minutes: 10))
          .toIso8601String(),
      'isExpired': _isUrlExpired(entry.fetchedAt),
    };
  }
}
