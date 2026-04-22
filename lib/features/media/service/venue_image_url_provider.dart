import '../model/kyc_image_cache_model.dart';

// ============================================================================
// VenueImageUrlProvider
// Manages venue image URLs (cover and gallery) with expiry detection
// ============================================================================

class VenueImageUrlProvider {
  /// Cache of fetched URLs with their fetch time
  /// Key format: "${venueId}_${imageKey}" for gallery images
  final Map<String, KycImageCacheEntry> _urlCache = {};

  /// Get cached venue image URL or return as-is if CDN URL (non-expiring)
  String getCachedImageUrl(String imageUrl) {
    // CDN URLs (public images) don't expire and can be used directly
    if (imageUrl.contains('.netlify.app') ||
        imageUrl.contains('cdn') ||
        !imageUrl.contains('X-Amz')) {
      return imageUrl;
    }

    // For signed URLs, check cache
    final cached = _urlCache[imageUrl];
    if (cached != null && !_isUrlExpired(cached.fetchedAt)) {
      return cached.downloadUrl;
    }

    return imageUrl;
  }

  /// Cache an image URL if it's a signed URL
  void cacheImageUrl(String imageUrl) {
    // Only cache signed URLs
    if (imageUrl.contains('X-Amz')) {
      _urlCache[imageUrl] = KycImageCacheEntry(
        downloadUrl: imageUrl,
        fetchedAt: DateTime.now(),
      );
    }
  }

  /// Check if URL is expired (considering 2-minute safety margin)
  bool _isUrlExpired(DateTime fetchedAt) {
    final expiryTime = fetchedAt.add(const Duration(minutes: 10));
    final safeMargin = expiryTime.subtract(const Duration(minutes: 2));
    return DateTime.now().isAfter(safeMargin);
  }

  /// Check if any cached URL is expiring soon
  bool isAnyUrlExpiringSoon() {
    return _urlCache.entries.any((entry) => _isUrlExpired(entry.value.fetchedAt));
  }

  /// Clear cache
  void clearCache() => _urlCache.clear();

  /// Get cache info for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': _urlCache.length,
      'expiringSoon': _urlCache.entries
          .where((e) => _isUrlExpired(e.value.fetchedAt))
          .length,
    };
  }
}
