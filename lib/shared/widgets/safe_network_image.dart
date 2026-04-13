import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/debug_dio_logging_interceptor.dart';
import '../../../core/network/token_manager.dart';

/// A widget that safely loads images from protected sources (like Cloudflare R2).
/// 
/// It first attempts to load using [Image.network]. If that fails (e.g. due to 
/// lack of authorization headers), it falls back to a manual HTTP GET request 
/// with appropriate headers and renders the image via [Image.memory].
class SafeNetworkImage extends StatefulWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  static final Map<String, Uint8List> _memoryCache = {};

  bool _isUsingFallback = false;
  bool _isFallbackLoading = false;
  bool _hasFallbackError = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (_memoryCache.containsKey(widget.url)) {
      _isUsingFallback = true;
      _imageBytes = _memoryCache[widget.url];
    }
  }

  Future<void> _loadFallback() async {
    if (_isFallbackLoading || _hasFallbackError) return;

    setState(() {
      _isFallbackLoading = true;
      _isUsingFallback = true;
    });

    try {
      final dio = Dio()..interceptors.add(DebugDioLoggingInterceptor());
      final tokenManager = TokenManager();
      final token = await tokenManager.getAccessToken();

      final response = await dio.get<List<int>>(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'image/*',
            'User-Agent': 'Flutter',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final bytes = Uint8List.fromList(response.data!);
      _memoryCache[widget.url] = bytes;

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isFallbackLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasFallbackError = true;
          _isFallbackLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return _buildPlaceholder();
    }

    if (_isUsingFallback) {
      if (_hasFallbackError) {
        return _buildPlaceholder(isError: true);
      }
      if (_isFallbackLoading || _imageBytes == null) {
        return _buildPlaceholder(isLoading: true);
      }
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return Image.network(
      widget.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(isLoading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        // Trigger fallback on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isUsingFallback) {
            _loadFallback();
          }
        });
        return _buildPlaceholder(isLoading: true);
      },
    );
  }

  Widget _buildPlaceholder({bool isLoading = false, bool isError = false}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isError ? Icons.broken_image_outlined : Icons.image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
