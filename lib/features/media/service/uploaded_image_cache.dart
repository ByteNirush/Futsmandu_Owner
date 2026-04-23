import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

// ============================================================================
// UploadedImageCache
// Stores uploaded image data with CDN URLs for instant UI display
// ============================================================================

class UploadedImage {
  const UploadedImage({
    required this.assetId,
    required this.key,
    this.cdnUrl,
    this.webpUrl,
    this.thumbUrl,
    this.temporaryBase64,
    required this.uploadedAt,
  });

  final String assetId;
  final String key;
  final String? cdnUrl;

  /// Processed WebP CDN URL — preferred for display (smaller, faster).
  final String? webpUrl;

  /// 320×240 thumbnail CDN URL — use for gallery grids.
  final String? thumbUrl;

  /// Base64-encoded image data for instant display while CDN is being processed.
  final String? temporaryBase64;

  final DateTime uploadedAt;

  /// Best display URL: webp > raw CDN > temporary base64.
  String? get displayUrl {
    if (webpUrl != null && webpUrl!.isNotEmpty) return webpUrl;
    if (cdnUrl != null && cdnUrl!.isNotEmpty) return cdnUrl;
    if (temporaryBase64 != null && temporaryBase64!.isNotEmpty) {
      return 'data:image/jpeg;base64,$temporaryBase64';
    }
    return null;
  }

  bool get hasMediaToDisplay => displayUrl != null;
  bool get isExpired {
    final now = DateTime.now();
    final expireTime = uploadedAt.add(const Duration(hours: 1));
    return now.isAfter(expireTime);
  }
}

class UploadedImageCache {
  static final UploadedImageCache _instance = UploadedImageCache._internal();

  factory UploadedImageCache() {
    return _instance;
  }

  UploadedImageCache._internal();

  final Map<String, UploadedImage> _cache = <String, UploadedImage>{};

  /// Bumped on every [save] / [updateCdnUrl] call so widgets can listen and
  /// rebuild reactively without polling.
  final ValueNotifier<int> revisionNotifier = ValueNotifier<int>(0);

  /// Store an uploaded image with optional temporary base64 for instant display.
  void save({
    required String assetId,
    required String key,
    String? cdnUrl,
    String? webpUrl,
    String? thumbUrl,
    List<int>? imageBytes,
  }) {
    String? tempBase64;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      tempBase64 = base64Encode(imageBytes);
    }

    _cache[assetId] = UploadedImage(
      assetId: assetId,
      key: key,
      cdnUrl: cdnUrl,
      webpUrl: webpUrl,
      thumbUrl: thumbUrl,
      temporaryBase64: tempBase64,
      uploadedAt: DateTime.now(),
    );
    revisionNotifier.value++;
  }

  /// Retrieve cached uploaded image
  UploadedImage? get(String assetId) {
    final cached = _cache[assetId];
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    // Clean up expired entries
    if (cached != null) {
      _cache.remove(assetId);
    }
    return null;
  }

  /// Update CDN / webp URLs after processing completes.
  void updateCdnUrl(String assetId, String cdnUrl, {String? webpUrl, String? thumbUrl}) {
    final cached = _cache[assetId];
    if (cached != null) {
      _cache[assetId] = UploadedImage(
        assetId: cached.assetId,
        key: cached.key,
        cdnUrl: cdnUrl,
        webpUrl: webpUrl ?? cached.webpUrl,
        thumbUrl: thumbUrl ?? cached.thumbUrl,
        temporaryBase64: cached.temporaryBase64,
        uploadedAt: cached.uploadedAt,
      );
      revisionNotifier.value++;
    }
  }

  /// Get cached by key (useful for venue images)
  UploadedImage? getByKey(String key) {
    for (final entry in _cache.entries) {
      if (entry.value.key == key && !entry.value.isExpired) {
        return entry.value;
      }
    }
    return null;
  }

  /// Generate a hash-based cache key for image identification
  static String generateCacheKey(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Clear all expired entries
  void cleanUpExpired() {
    _cache.removeWhere((_, value) => value.isExpired);
  }

  /// Clear specific asset
  void remove(String assetId) {
    _cache.remove(assetId);
  }

  /// Clear all
  void clear() {
    _cache.clear();
  }

  /// Get cache size
  int get size => _cache.length;

  /// Get all cached images
  List<UploadedImage> getAll() {
    cleanUpExpired();
    return _cache.values.toList();
  }
}

/// Convenience accessor
final uploadedImageCache = UploadedImageCache();
