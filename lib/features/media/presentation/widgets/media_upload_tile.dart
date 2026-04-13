import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'uploaded_image_display.dart';

// ============================================================================
// MediaUploadTile
// A premium, animated upload tile with:
//  - Instant local image preview on pick
//  - Smooth animated upload progress ring
//  - Status badge (idle / uploading / done / error)
//  - Tap to expand full-screen preview
//  - Re-upload via long press or action button
// ============================================================================

enum UploadTileState { idle, uploading, done, error }

class MediaUploadTile extends StatefulWidget {
  const MediaUploadTile({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.localImagePath,
    this.assetId,
    this.networkImageUrl,
    this.uploadState = UploadTileState.idle,
    this.uploadProgress = 0,
    this.statusMessage,
    this.errorMessage,
    this.onTap,
    this.onRetry,
    this.accentColor,
    this.isRequired = false,
    this.isAlreadySubmitted = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String? localImagePath;
  final String? assetId;
  final String? networkImageUrl;
  final UploadTileState uploadState;
  final double uploadProgress;
  final String? statusMessage;
  final String? errorMessage;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final Color? accentColor;
  final bool isRequired;
  final bool isAlreadySubmitted;

  bool get hasImage =>
      localImagePath != null ||
      assetId != null ||
      networkImageUrl != null;

  @override
  State<MediaUploadTile> createState() => _MediaUploadTileState();
}

class _MediaUploadTileState extends State<MediaUploadTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    if (widget.uploadState == UploadTileState.uploading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(MediaUploadTile old) {
    super.didUpdateWidget(old);
    if (widget.uploadState == UploadTileState.uploading) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
    } else {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.accentColor ?? const Color(0xFF00C896);

  void _openFullPreview(BuildContext context) {
    if (!widget.hasImage) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: _FullScreenImageViewer(
            localImagePath: widget.localImagePath,
            assetId: widget.assetId,
            networkImageUrl: widget.networkImageUrl,
            label: widget.label,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = widget.uploadState == UploadTileState.done ||
        widget.isAlreadySubmitted;
    final isUploading = widget.uploadState == UploadTileState.uploading;
    final isError = widget.uploadState == UploadTileState.error;

    final borderColor = isError
        ? colorScheme.error.withValues(alpha: 0.6)
        : isDone
            ? _accentColor.withValues(alpha: 0.5)
            : colorScheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isDone ? 1.5 : 1),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: (isDone ? _accentColor : colorScheme.shadow)
                .withValues(alpha: isDone ? 0.08 : 0.04),
            blurRadius: isDone ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area
            if (widget.hasImage)
              _PreviewArea(
                localImagePath: widget.localImagePath,
                assetId: widget.assetId,
                networkImageUrl: widget.networkImageUrl,
                isUploading: isUploading,
                uploadProgress: widget.uploadProgress,
                uploadState: widget.uploadState,
                accentColor: _accentColor,
                shimmerAnimation: _shimmerAnimation,
                onTap: () => _openFullPreview(context),
              )
            else
              _EmptyPreviewArea(
                icon: widget.icon,
                accentColor: _accentColor,
                isUploading: isUploading,
                uploadProgress: widget.uploadProgress,
                shimmerAnimation: _shimmerAnimation,
              ),

            // Content area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status dot
                  _StatusIndicator(
                    state: widget.uploadState,
                    isAlreadySubmitted: widget.isAlreadySubmitted,
                    accentColor: _accentColor,
                  ),
                  const SizedBox(width: 12),
                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (widget.isRequired && !isDone)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            key: ValueKey(widget.statusMessage ?? widget.subtitle),
                            isUploading
                                ? (widget.statusMessage ?? 'Uploading…')
                                : isError
                                    ? (widget.errorMessage ?? 'Upload failed')
                                    : isDone
                                        ? 'Uploaded successfully'
                                        : widget.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isError
                                      ? colorScheme.error
                                      : isDone
                                          ? _accentColor
                                          : colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action button
                  _ActionButton(
                    state: widget.uploadState,
                    isAlreadySubmitted: widget.isAlreadySubmitted,
                    accentColor: _accentColor,
                    onTap: isUploading ? null : widget.onTap,
                    onRetry: widget.onRetry,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _PreviewArea — shown when image exists
// ============================================================================

class _PreviewArea extends StatelessWidget {
  const _PreviewArea({
    required this.localImagePath,
    required this.assetId,
    required this.networkImageUrl,
    required this.isUploading,
    required this.uploadProgress,
    required this.uploadState,
    required this.accentColor,
    required this.shimmerAnimation,
    required this.onTap,
  });

  final String? localImagePath;
  final String? assetId;
  final String? networkImageUrl;
  final bool isUploading;
  final double uploadProgress;
  final UploadTileState uploadState;
  final Color accentColor;
  final Animation<double> shimmerAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            _buildImage(),

            // Upload overlay
            if (isUploading) _UploadProgressOverlay(progress: uploadProgress),

            // Done overlay pulse
            if (uploadState == UploadTileState.done)
              _DoneOverlay(accentColor: accentColor),

            // Expand hint
            Positioned(
              bottom: 8,
              right: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    color: Colors.black38,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.open_in_full_rounded,
                            size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tap to expand',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (localImagePath != null) {
      return Image.file(
        File(localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    return UploadedImageDisplay(
      assetId: assetId,
      image: networkImageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      ),
    );
  }
}

// ============================================================================
// _EmptyPreviewArea — shown when no image yet
// ============================================================================

class _EmptyPreviewArea extends StatelessWidget {
  const _EmptyPreviewArea({
    required this.icon,
    required this.accentColor,
    required this.isUploading,
    required this.uploadProgress,
    required this.shimmerAnimation,
  });

  final IconData icon;
  final Color accentColor;
  final bool isUploading;
  final double uploadProgress;
  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.06),
            accentColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: isUploading
          ? _UploadProgressOverlay(progress: uploadProgress, isOverlay: false)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// _UploadProgressOverlay
// ============================================================================

class _UploadProgressOverlay extends StatelessWidget {
  const _UploadProgressOverlay({
    required this.progress,
    this.isOverlay = true,
  });
  final double progress;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
              if (progress > 0)
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Uploading…',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (!isOverlay) {
      return Center(child: content);
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black54,
          child: Center(child: content),
        ),
      ),
    );
  }
}

// ============================================================================
// _DoneOverlay
// ============================================================================

class _DoneOverlay extends StatelessWidget {
  const _DoneOverlay({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

// ============================================================================
// _StatusIndicator
// ============================================================================

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.state,
    required this.isAlreadySubmitted,
    required this.accentColor,
  });
  final UploadTileState state;
  final bool isAlreadySubmitted;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone =
        state == UploadTileState.done || isAlreadySubmitted;

    Color dotColor;
    Widget? child;

    if (state == UploadTileState.uploading) {
      dotColor = colorScheme.primary;
      child = SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    } else if (state == UploadTileState.error) {
      dotColor = colorScheme.error;
      child = const Icon(Icons.close_rounded, size: 12, color: Colors.white);
    } else if (isDone) {
      dotColor = accentColor;
      child = const Icon(Icons.check_rounded, size: 12, color: Colors.white);
    } else {
      dotColor = colorScheme.outlineVariant;
      child = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}

// ============================================================================
// _ActionButton
// ============================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.state,
    required this.isAlreadySubmitted,
    required this.accentColor,
    required this.onTap,
    required this.onRetry,
  });
  final UploadTileState state;
  final bool isAlreadySubmitted;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = state == UploadTileState.done || isAlreadySubmitted;

    if (state == UploadTileState.uploading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (state == UploadTileState.error) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: colorScheme.error,
              iconSize: 20,
              tooltip: 'Retry',
            ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.upload_rounded),
            iconSize: 20,
            tooltip: 'Try another image',
          ),
        ],
      );
    }

    return Material(
      color: isDone
          ? accentColor.withValues(alpha: 0.1)
          : colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone
                    ? Icons.edit_outlined
                    : Icons.upload_file_rounded,
                size: 16,
                color: isDone ? accentColor : colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                isDone ? 'Change' : 'Upload',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDone
                      ? accentColor
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _FullScreenImageViewer
// ============================================================================

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({
    required this.label,
    this.localImagePath,
    this.assetId,
    this.networkImageUrl,
  });

  final String label;
  final String? localImagePath;
  final String? assetId;
  final String? networkImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.black87),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Hero(
                tag: 'preview_$label',
                child: _buildImage(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black38,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          color: Colors.black38,
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (localImagePath != null) {
      return Image.file(File(localImagePath!), fit: BoxFit.contain);
    }
    return UploadedImageDisplay(
      assetId: assetId,
      image: networkImageUrl,
      height: double.infinity,
      width: double.infinity,
      fit: BoxFit.contain,
    );
  }
}
