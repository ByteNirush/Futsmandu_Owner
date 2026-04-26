import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../media/controller/media_upload_controller.dart';
import '../../../media/presentation/widgets/media_upload_tile.dart';
import '../../../media/presentation/widgets/uploaded_image_display.dart';
import '../../../media/service/media_upload_service.dart';

// ============================================================================
// VenueCoverImagePicker
// Beautiful cover image picker with instant local preview
// ============================================================================

class VenueCoverImagePicker extends StatefulWidget {
  const VenueCoverImagePicker({
    super.key,
    required this.venueId,
    this.initialImageUrl,
    this.onUploaded,
    this.onLocalPicked,
    this.localImagePath,
  });

  final String venueId;
  final String? initialImageUrl;
  final void Function(String assetId, String? cdnUrl)? onUploaded;
  final void Function(String path)? onLocalPicked;
  final String? localImagePath;

  @override
  State<VenueCoverImagePicker> createState() => _VenueCoverImagePickerState();
}

class _VenueCoverImagePickerState extends State<VenueCoverImagePicker>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final MediaUploadController _controller =
      MediaUploadController(service: MediaUploadService());

  UploadTileState _state = UploadTileState.idle;
  double _progress = 0;
  String? _status;
  String? _localPath;
  String? _uploadedAssetId;
  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _localPath = widget.localImagePath;
    if (_localPath != null || widget.initialImageUrl != null) {
      _state = UploadTileState.done;
    }

    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;

    HapticFeedback.mediumImpact();

    // Instant local preview
    setState(() {
      _localPath = picked.path;
      _state = UploadTileState.uploading;
      _progress = 0;
      _status = 'Uploading cover image…';
    });

    widget.onLocalPicked?.call(picked.path);

    try {
      final bytes = await picked.readAsBytes();
      final contentType = _guessContentType(picked.name);

      final result = await _controller.uploadVenueCover(
        venueId: widget.venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: true,
      );

      if (!mounted) return;

      setState(() {
        _state = UploadTileState.done;
        _progress = 1.0;
        _uploadedAssetId = result.assetId;
      });

      _checkAnim.forward(from: 0);
      HapticFeedback.lightImpact();
      widget.onUploaded?.call(result.assetId ?? '', result.cdnUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = UploadTileState.error);
    }
  }

  String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  bool get _hasImage =>
      _localPath != null || widget.initialImageUrl != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final isUploading = _state == UploadTileState.uploading;
    final isDone = _state == UploadTileState.done;
    final isError = _state == UploadTileState.error;

    return GestureDetector(
      onTap: isUploading ? null : _pick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isError
                ? cs.error.withValues(alpha: 0.5)
                : isDone
                    ? accent.withValues(alpha: 0.4)
                    : cs.outlineVariant,
            width: isDone ? 2 : 1,
          ),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or placeholder
              if (_hasImage)
                _localPath != null
                    ? Image.file(File(_localPath!), fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _Placeholder(accent: accent))
                    : UploadedImageDisplay(
                        assetId: _uploadedAssetId,
                        image: widget.initialImageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: _Placeholder(accent: accent),
                      )
              else
                _Placeholder(accent: accent),

              // Upload overlay
              if (isUploading)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: cs.scrim.withValues(alpha: 0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: _progress > 0 ? _progress : null,
                                  strokeWidth: 3,
                                  backgroundColor: cs.onPrimary.withValues(alpha: 0.24),
                                  valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                                ),
                                if (_progress > 0)
                                  Center(
                                    child: Text(
                                      '${(_progress * 100).toInt()}%',
                                      style: TextStyle(
                                        color: cs.onPrimary,
                                        fontWeight: AppFontWeights.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _status ?? 'Uploading…',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: AppFontWeights.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Done check
              if (isDone)
                Positioned(
                  top: 10,
                  right: 10,
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: cs.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ),

              // Error state
              if (isError)
                Container(
                  color: cs.scrim.withValues(alpha: 0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: cs.onPrimary,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload failed',
                          style: TextStyle(color: cs.onPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pick,
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onPrimary,
                            backgroundColor: cs.onPrimary.withValues(alpha: 0.24),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tap hint (idle)
              if (!isUploading && !isError)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs2,
                            vertical: AppSpacing.xxs,
                          ),
                          color: cs.scrim.withValues(alpha: 0.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDone
                                    ? Icons.edit_rounded
                                    : Icons.add_photo_alternate_outlined,
                                size: 14,
                                color: cs.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDone
                                    ? 'Tap to change cover'
                                    : 'Tap to add cover image',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: AppFontWeights.medium,
                                ),
                              ),
                            ],
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
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: accent.withValues(alpha: 0.04),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Cover Photo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG or WEBP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VenueGalleryUploader
// Multi-image gallery upload grid with add/remove and instant preview
// ============================================================================

class GalleryImage {
  GalleryImage({
    this.localPath,
    this.assetId,
    this.cdnUrl,
    this.isUploading = false,
    this.progress = 0.0,
    this.hasError = false,
    required this.id,
  });

  final String id;
  String? localPath;
  String? assetId;
  String? cdnUrl;
  bool isUploading;
  double progress;
  bool hasError;

  bool get hasImage => localPath != null || assetId != null || cdnUrl != null;
}

class VenueGalleryUploader extends StatefulWidget {
  const VenueGalleryUploader({
    super.key,
    required this.venueId,
    this.initialImages = const [],
    this.maxImages = 8,
    this.onImagesChanged,
  });

  final String venueId;
  final List<String> initialImages; // list of CDN URLs
  final int maxImages;
  final void Function(List<GalleryImage> images)? onImagesChanged;

  @override
  State<VenueGalleryUploader> createState() => _VenueGalleryUploaderState();
}

class _VenueGalleryUploaderState extends State<VenueGalleryUploader> {
  final ImagePicker _picker = ImagePicker();
  final MediaUploadService _uploadService = MediaUploadService();
  final List<GalleryImage> _images = [];
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    for (final url in widget.initialImages) {
      _images.add(GalleryImage(
        id: '${_nextId++}',
        cdnUrl: url,
      ));
    }
  }

  @override
  void dispose() {
    _uploadService;
    super.dispose();
  }

  Future<void> _addImages() async {
    final remaining = widget.maxImages - _images.length;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(imageQuality: 85, limit: remaining);
    if (picked.isEmpty || !mounted) return;

    HapticFeedback.selectionClick();

    final newImages = picked.map((xf) => GalleryImage(
          id: '${_nextId++}',
          localPath: xf.path,
          isUploading: true,
        )).toList();

    setState(() => _images.addAll(newImages));
    widget.onImagesChanged?.call(_images);

    // Upload each
    for (int i = 0; i < newImages.length; i++) {
      final img = newImages[i];
      final xf = picked[i];
      _uploadSingle(img, xf.path, xf.name);
    }
  }

  Future<void> _uploadSingle(
      GalleryImage img, String path, String name) async {
    try {
      final bytes = await File(path).readAsBytes();
      final contentType = _guessContentType(name);

      final result = await _uploadService.uploadVenueGalleryImage(
        venueId: widget.venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: true,
        onUploadProgress: (p) {
          if (!mounted) return;
          setState(() => img.progress = p);
          widget.onImagesChanged?.call(_images);
        },
        onStatusMessage: (msg) {},
      );

      if (!mounted) return;

      setState(() {
        img.isUploading = false;
        img.assetId = result.assetId;
        img.cdnUrl = result.cdnUrl;
        img.progress = 1.0;
        img.hasError = false;
      });

      HapticFeedback.lightImpact();
      widget.onImagesChanged?.call(_images);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        img.isUploading = false;
        img.hasError = true;
      });
      widget.onImagesChanged?.call(_images);
    }
  }

  void _removeImage(GalleryImage img) {
    HapticFeedback.mediumImpact();
    setState(() => _images.remove(img));
    widget.onImagesChanged?.call(_images);
  }

  String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final canAdd = _images.length < widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gallery Images',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: AppFontWeights.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_images.length}/${widget.maxImages}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: AppFontWeights.semiBold,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _images.length + (canAdd ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _images.length) {
              return _AddImageCell(onTap: _addImages, accent: accent);
            }
            return _GalleryCell(
              image: _images[index],
              onRemove: () => _removeImage(_images[index]),
              onRetry: () {
                final img = _images[index];
                if (img.localPath != null) {
                  final path = img.localPath!;
                  setState(() {
                    img.isUploading = true;
                    img.hasError = false;
                  });
                  _uploadSingle(
                      img, path, path.split('/').last);
                }
              },
              accentColor: accent,
            );
          },
        ),
        if (_images.isEmpty)
          GestureDetector(
            onTap: _addImages,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add gallery photos',
                      style: TextStyle(
                          color: accent, fontWeight: AppFontWeights.semiBold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GalleryCell extends StatelessWidget {
  const _GalleryCell({
    required this.image,
    required this.onRemove,
    required this.onRetry,
    required this.accentColor,
  });
  final GalleryImage image;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (image.localPath != null)
            Image.file(File(image.localPath!), fit: BoxFit.cover)
          else if (image.cdnUrl != null || image.assetId != null)
            UploadedImageDisplay(
              assetId: image.assetId,
              image: image.cdnUrl,
              fit: BoxFit.cover,
            )
          else
            Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),

          // Upload overlay
          if (image.isUploading)
            Container(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: image.progress > 0 ? image.progress : null,
                        strokeWidth: 2.5,
                        backgroundColor:
                            Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.24),
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    if (image.progress > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(image.progress * 100).toInt()}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: AppFontWeights.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Error overlay
          if (image.hasError)
            Container(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.24),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Done check
          if (!image.isUploading && !image.hasError && image.hasImage)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 10,
                ),
              ),
            ),

          // Remove button
          if (!image.isUploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddImageCell extends StatelessWidget {
  const _AddImageCell({required this.onTap, required this.accent});
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: accent, size: 28),
              const SizedBox(height: 2),
              Text(
                'Add',
                style: TextStyle(
                  color: accent,
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
