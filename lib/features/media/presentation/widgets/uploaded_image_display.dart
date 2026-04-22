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
// ============================================================================

class UploadedImageDisplay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Try to find image from cache first
    UploadedImage? cached;

    if (assetId != null && assetId!.isNotEmpty) {
      cached = uploadedImageCache.get(assetId!);
    } else if (cacheKey != null && cacheKey!.isNotEmpty) {
      cached = uploadedImageCache.getByKey(cacheKey!);
    }

    // Prioritize: cached display URL > provided image > placeholder
    final displayUrl = cached?.displayUrl ?? image;

    if (displayUrl == null || displayUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return _buildImage(displayUrl);
  }

  Widget _buildImage(String url) {
    try {
      final isBase64 = url.startsWith('data:');

      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: width,
          child: isBase64
              ? Image.memory(
                  // Decode base64
                  _decodeBase64(url),
                  fit: fit,
                  errorBuilder: _onImageError,
                )
              : _NetworkImageWithCleanClient(
                  url: url,
                  fit: fit,
                  errorBuilder: _onImageError,
                ),
        ),
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: height,
            width: width,
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey[600],
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
    if (errorBuilder != null) {
      return errorBuilder!(context, error, stackTrace);
    }
    return _buildPlaceholder();
  }

  static Uint8List _decodeBase64(String url) {
    // Remove data URI prefix if present
    var base64String = url;
    if (url.contains(',')) {
      base64String = url.split(',')[1];
    }
    // Remove any whitespace
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
        color: Colors.grey[300],
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
