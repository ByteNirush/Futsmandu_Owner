import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../service/uploaded_image_cache.dart';

// ============================================================================
// UploadedImageDisplay
// Displays cached uploaded images with intelligent fallbacks:
// 1. Asset ID provided → try cache first (instant display)
// 2. If cached → use base64 data URL (instant)
// 3. If CDN URL → use network image (after processing)
// 4. Fallback to placeholder if nothing available
//
// Reactive: subscribes to uploadedImageCache.revisionNotifier so the widget
// automatically upgrades from the base64 preview to the CDN/WebP URL when
// polling completes — no manual refresh needed.
// ============================================================================

class UploadedImageDisplay extends StatefulWidget {
  const UploadedImageDisplay({
    super.key,
    this.image,
    this.assetId,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorBuilder,
    this.cacheKey,
  });

  /// Asset ID to look up in cache
  final String? assetId;

  /// Image URL directly
  final String? image;

  /// Image height
  final double height;

  /// Image width
  final double width;

  /// Box fit
  final BoxFit fit;

  /// Border radius
  final double borderRadius;

  /// Placeholder widget
  final Widget? placeholder;

  /// Error builder
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Custom cache key (advanced)
  final String? cacheKey;

  @override
  State<UploadedImageDisplay> createState() => _UploadedImageDisplayState();
}

class _UploadedImageDisplayState extends State<UploadedImageDisplay> {
  @override
  void initState() {
    super.initState();
    // Subscribe so the widget upgrades from base64 preview → CDN/WebP URL
    // the moment polling completes and the cache is revised.
    uploadedImageCache.revisionNotifier.addListener(_onCacheRevised);
  }

  @override
  void dispose() {
    uploadedImageCache.revisionNotifier.removeListener(_onCacheRevised);
    super.dispose();
  }

  void _onCacheRevised() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Try to find image from cache first
    UploadedImage? cached;

    if (widget.assetId != null && widget.assetId!.isNotEmpty) {
      cached = uploadedImageCache.get(widget.assetId!);
    } else if (widget.cacheKey != null && widget.cacheKey!.isNotEmpty) {
      cached = uploadedImageCache.getByKey(widget.cacheKey!);
    }

    // Prioritize: cached display URL > provided image > placeholder
    final displayUrl = cached?.displayUrl ?? widget.image;

    if (displayUrl == null || displayUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    return _buildImage(context, displayUrl);
  }

  Widget _buildImage(BuildContext context, String url) {
    try {
      final isBase64 = url.startsWith('data:');

      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: isBase64
              ? Image.memory(
                  _decodeBase64(url),
                  fit: widget.fit,
                  errorBuilder: _onImageError,
                )
              : _NetworkImageWithCleanClient(
                  url: url,
                  fit: widget.fit,
                  errorBuilder: _onImageError,
                ),
        ),
      );
    } catch (e) {
      return _buildPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return widget.placeholder ??
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            height: widget.height,
            width: widget.width,
            color: cs.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: cs.onSurfaceVariant,
                size: 48,
              ),
            ),
          ),
        );
  }

  Widget _onImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace);
    }
    return _buildPlaceholder(context);
  }

  static Uint8List _decodeBase64(String url) {
    var base64String = url;
    if (url.contains(',')) {
      base64String = url.split(',')[1];
    }
    base64String = base64String.replaceAll(RegExp(r'\s'), '');
    return Uint8List.fromList(base64Decode(base64String));
  }
}

// ============================================================================
// _NetworkImageWithCleanClient
// Fetches network images using a clean HttpClient that doesn't inherit
// global Dio interceptors or Authorization headers.
// This is critical for signed URLs (like R2) where extra headers invalidate
// the signature and cause 403 errors.
// ============================================================================
class _NetworkImageWithCleanClient extends StatefulWidget {
  const _NetworkImageWithCleanClient({
    required this.url,
    required this.fit,
    required this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final ImageErrorWidgetBuilder errorBuilder;

  @override
  State<_NetworkImageWithCleanClient> createState() =>
      _NetworkImageWithCleanClientState();
}

class _NetworkImageWithCleanClientState
    extends State<_NetworkImageWithCleanClient> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  @override
  void didUpdateWidget(_NetworkImageWithCleanClient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _fetchImage();
    }
  }

  Future<void> _fetchImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use a clean HttpClient without any inherited headers
      final client = HttpClient();
      client.autoUncompress = true;

      final request = await client.getUrl(Uri.parse(widget.url));
      // Do NOT add any headers - let the signed URL work as-is

      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.expand((chunk) => chunk).toList();
        if (mounted) {
          setState(() {
            _imageBytes = Uint8List.fromList(bytes);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null || _imageBytes == null) {
      return widget.errorBuilder(context, _error ?? 'Failed to load', null);
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder,
    );
  }
}

// Utility extension for easy access
extension ImageDisplayHelper on BuildContext {
  /// Quick widget builder for uploaded images
  Widget displayUploadedImage({
    required String? assetId,
    String? imageUrl,
    double height = 200,
    double width = double.infinity,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 0,
  }) {
    return UploadedImageDisplay(
      assetId: assetId,
      image: imageUrl,
      height: height,
      width: width,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}
