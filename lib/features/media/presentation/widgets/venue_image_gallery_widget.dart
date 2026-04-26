import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';

// ============================================================================
// VenueImageGalleryWidget
// Premium gallery manager: hover overlays, empty-state, status feedback,
// count badge, and delete confirmation bottom sheet.
// ============================================================================

enum _UploadStatusKind { none, uploading, success, error }

class VenueImageGalleryWidget extends StatefulWidget {
  const VenueImageGalleryWidget({
    super.key,
    required this.label,
    required this.galleryImages,
    this.onImageTap,
    this.onDeleteImage,
    this.onAddImage,
    this.isUploading = false,
    this.uploadStatusMessage,
    this.maxImages = 10,
    this.crossAxisCount = 3,
  });

  final String label;
  final List<String> galleryImages;
  final Function(int index, String imageUrl)? onImageTap;
  final Function(int index)? onDeleteImage;

  /// Called when the user taps the in-widget "Add Photo" button
  /// (only shown in the empty-state; main add button lives in the parent).
  final VoidCallback? onAddImage;

  final bool isUploading;

  /// Prefix with 'SUCCESS:' for success, 'ERROR:' for error,
  /// or plain text for uploading/progress messages.
  final String? uploadStatusMessage;

  final int maxImages;
  final int crossAxisCount;

  @override
  State<VenueImageGalleryWidget> createState() =>
      _VenueImageGalleryWidgetState();
}

class _VenueImageGalleryWidgetState extends State<VenueImageGalleryWidget> {
  int? _hoveredIndex;

  // ── Status helpers ──────────────────────────────────────────────────────

  _UploadStatusKind get _statusKind {
    if (widget.uploadStatusMessage == null) return _UploadStatusKind.none;
    if (widget.isUploading) return _UploadStatusKind.uploading;
    final msg = widget.uploadStatusMessage!;
    if (msg.startsWith('SUCCESS:') ||
        msg.toLowerCase().contains('success') ||
        msg.toLowerCase().contains('added')) {
      return _UploadStatusKind.success;
    }
    if (msg.toLowerCase().contains('fail') ||
        msg.toLowerCase().contains('error') ||
        msg.toLowerCase().contains('maximum')) {
      return _UploadStatusKind.error;
    }
    return _UploadStatusKind.uploading;
  }

  String get _cleanStatusMessage {
    final msg = widget.uploadStatusMessage ?? '';
    return msg.replaceFirst(RegExp(r'^(SUCCESS:|ERROR:)\s*'), '').trim();
  }

  // ── Delete confirmation ─────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.errorContainer,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 28,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Remove this photo?',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeights.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'This photo will be removed from your gallery. You can always add it again.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Keep'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      widget.onDeleteImage?.call(index);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageCount = widget.galleryImages.length;
    final atMax = imageCount >= widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: label + count badge ──────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                  ),
            ),
            const Spacer(),
            if (imageCount > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: atMax
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$imageCount / ${widget.maxImages}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: atMax
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                        fontWeight: AppFontWeights.bold,
                      ),
                ),
              ),
          ],
        ),

        // ── Empty state ───────────────────────────────────────────────────
        if (imageCount == 0 && !widget.isUploading)
          _buildEmptyState(context, colorScheme),

        // ── Grid ─────────────────────────────────────────────────────────
        if (imageCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisSpacing: AppSpacing.xs,
            ),
            itemCount: imageCount,
            itemBuilder: (context, index) {
              final imageUrl = widget.galleryImages[index];
              return _buildImageTile(context, index, imageUrl, colorScheme);
            },
          ),
        ],

        // ── Status row ────────────────────────────────────────────────────
        if (widget.isUploading || widget.uploadStatusMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildStatusRow(context, colorScheme),
        ],
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: GestureDetector(
        onTap: widget.onAddImage,
        child: DashedBorderContainer(
          color: colorScheme.outline,
          borderRadius: 12,
          child: SizedBox(
            width: double.infinity,
            height: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add your first gallery photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: AppFontWeights.semiBold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to browse from your photo library',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Individual tile ───────────────────────────────────────────────────────

  Widget _buildImageTile(
    BuildContext context,
    int index,
    String imageUrl,
    ColorScheme colorScheme,
  ) {
    final hovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onImageTap?.call(index, imageUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Image ─────────────────────────────────────────────
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Failed',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hover/tap overlay (AnimatedOpacity) ───────────────
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Delete button ─────────────────────────────────────
                if (widget.onDeleteImage != null)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: AnimatedOpacity(
                      opacity: hovered ? 1.0 : 0.75,
                      duration: const Duration(milliseconds: 180),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmDelete(context, index),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.error,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
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
      ),
    );
  }

  // ── Status row ────────────────────────────────────────────────────────────

  Widget _buildStatusRow(BuildContext context, ColorScheme colorScheme) {
    final kind = _statusKind;
    final message = _cleanStatusMessage;

    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (kind) {
      case _UploadStatusKind.success:
        iconColor = colorScheme.tertiary;
        bgColor = colorScheme.tertiaryContainer;
        icon = Icons.check_circle_rounded;
      case _UploadStatusKind.error:
        iconColor = colorScheme.error;
        bgColor = colorScheme.errorContainer;
        icon = Icons.error_rounded;
      case _UploadStatusKind.uploading:
      case _UploadStatusKind.none:
        iconColor = colorScheme.primary;
        bgColor = colorScheme.primaryContainer;
        icon = Icons.cloud_upload_outlined;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(kind),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    message.isNotEmpty ? message : 'Uploading…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: iconColor,
                          fontWeight: AppFontWeights.medium,
                        ),
                  ),
                ),
              ],
            ),
            if (kind == _UploadStatusKind.uploading) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DashedBorderContainer — lightweight dashed-border painter
// ============================================================================

class DashedBorderContainer extends StatelessWidget {
  const DashedBorderContainer({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 12,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  final Widget child;
  final Color? color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.outline;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: c,
        radius: borderRadius,
        dashWidth: dashWidth,
        dashGap: dashGap,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final drawEnd = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, drawEnd), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap;
}
