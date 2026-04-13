import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.downloadUrl;
    _urlFetchedAt = DateTime.now();
  }

  @override
  void didUpdateWidget(RefreshableKycImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloadUrl != widget.downloadUrl) {
      _currentUrl = widget.downloadUrl;
      _urlFetchedAt = DateTime.now();
      _urlExpiredMessage = null;
    }
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _urlExpiredMessage = 'Failed to refresh URL. Please try again.';
        _isRefreshing = false;
      });
    }
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showFullPreview,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
                    cacheHeight: (widget.height * 1.5).toInt(),
                    cacheWidth: (widget.width * 1.2).toInt(),
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          '❌ Image load error: $error for ${widget.docType}');
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URL Expiring Soon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _urlExpiredMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.black38,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.open_in_full_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'View',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
