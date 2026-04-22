import 'package:flutter/material.dart';
import 'dart:async';

// ============================================================================
// RefreshableKycImageDisplay
// Displays KYC images with automatic refresh on URL expiration
// ============================================================================

class RefreshableKycImageDisplay extends StatefulWidget {
  const RefreshableKycImageDisplay({
    super.key,
    required this.downloadUrl,
    required this.docType,
    required this.onRefreshUrl,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  final String downloadUrl;
  final String docType;
  final Future<String> Function() onRefreshUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final double borderRadius;

  @override
  State<RefreshableKycImageDisplay> createState() =>
      _RefreshableKycImageDisplayState();
}

class _RefreshableKycImageDisplayState
    extends State<RefreshableKycImageDisplay> {
  late String _currentUrl;
  late DateTime _urlFetchedAt;
  bool _isRefreshing = false;
  String? _urlExpiredMessage;
  Timer? _expiryCheckTimer;
  bool _didAutoRefreshAfterError = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.downloadUrl;
    _urlFetchedAt = DateTime.now();
    _startExpiryWatcher();
  }

  @override
  void didUpdateWidget(RefreshableKycImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloadUrl != widget.downloadUrl) {
      _currentUrl = widget.downloadUrl;
      _urlFetchedAt = DateTime.now();
      _urlExpiredMessage = null;
      _didAutoRefreshAfterError = false;
    }
  }

  @override
  void dispose() {
    _expiryCheckTimer?.cancel();
    super.dispose();
  }

  bool get _isUrlExpiringSoon {
    final expiryTime = _urlFetchedAt.add(const Duration(minutes: 10));
    final safeMargin = expiryTime.subtract(const Duration(minutes: 2));
    return DateTime.now().isAfter(safeMargin);
  }

  Future<void> _refreshUrl() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final newUrl = await widget.onRefreshUrl();
      if (!mounted) return;

      setState(() {
        _currentUrl = newUrl;
        _urlFetchedAt = DateTime.now();
        _urlExpiredMessage = null;
        _isRefreshing = false;
        _didAutoRefreshAfterError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _urlExpiredMessage = 'Failed to refresh URL. Please try again.';
        _isRefreshing = false;
      });
    }
  }

  void _startExpiryWatcher() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _isRefreshing) return;
      if (_isUrlExpiringSoon) {
        _refreshUrl();
      }
    });
  }

  int? _safeCacheDimension(
    double value, {
    required double multiplier,
    double? fallback,
  }) {
    final base = value.isFinite && value > 0
        ? value
        : (fallback != null && fallback.isFinite && fallback > 0
              ? fallback
              : null);

    if (base == null) return null;

    final scaled = base * multiplier;
    if (!scaled.isFinite || scaled <= 0) return null;

    return scaled.round();
  }

  void _showFullPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              _currentUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text('Failed to load image'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshUrl,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final cacheHeight = _safeCacheDimension(
      widget.height,
      multiplier: 1.5,
    );
    final cacheWidth = _safeCacheDimension(
      widget.width,
      multiplier: 1.2,
      fallback: viewportWidth,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showFullPreview,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with caching
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius),
                  child: Image.network(
                    _currentUrl,
                    fit: widget.fit,
                    gaplessPlayback: true,
                    cacheHeight: cacheHeight,
                    cacheWidth: cacheWidth,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          '❌ Image load error: $error for ${widget.docType}');
                      if (!_didAutoRefreshAfterError && !_isRefreshing) {
                        _didAutoRefreshAfterError = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _refreshUrl();
                          }
                        });
                      }
                      return Container(
                        color: cs.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _refreshUrl,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                // View button overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildOverlayButton(),
                ),
                // Expiry warning badge
                if (_isUrlExpiringSoon && !_isRefreshing)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'URL Expiring Soon',
                        style: TextStyle(
                          color: cs.onTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_isUrlExpiringSoon) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _refreshUrl,
            icon: _isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh URL'),
          ),
        ],
        if (_urlExpiredMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.error.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _urlExpiredMessage!,
                    style: textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverlayButton() {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cs.scrim.withValues(alpha: 0.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_full_rounded, size: 12, color: cs.onPrimary),
            const SizedBox(width: 4),
            Text(
              'View',
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
