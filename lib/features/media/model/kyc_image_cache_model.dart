// ============================================================================
// KycImageCacheEntry
// Represents a cached KYC image URL with expiry information
// ============================================================================

class KycImageCacheEntry {
  const KycImageCacheEntry({
    required this.downloadUrl,
    required this.fetchedAt,
  });

  final String downloadUrl;
  final DateTime fetchedAt;

  /// Check if URL is still valid (safe margin: 2 minutes)
  bool get isExpired {
    final expiryTime = fetchedAt.add(const Duration(minutes: 10));
    final safeMargin = expiryTime.subtract(const Duration(minutes: 2));
    return DateTime.now().isAfter(safeMargin);
  }

  /// Time until URL expires in seconds
  int get secondsUntilExpiry {
    final expiryTime = fetchedAt.add(const Duration(minutes: 10));
    final remaining = expiryTime.difference(DateTime.now());
    return remaining.inSeconds;
  }

  @override
  String toString() => 'KycImageCacheEntry('
      'url: ${downloadUrl.substring(0, 50)}..., '
      'fetchedAt: $fetchedAt, '
      'isExpired: $isExpired)';
}
