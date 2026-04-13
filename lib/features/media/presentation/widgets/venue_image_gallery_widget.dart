import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';

// ============================================================================
// VenueImageGalleryWidget
// Display venue gallery images in a scrollable grid with full preview
// ============================================================================

class VenueImageGalleryWidget extends StatefulWidget {
  const VenueImageGalleryWidget({
    super.key,
    required this.label,
    required this.galleryImages,
    this.onImageTap,
    this.onDeleteImage,
    this.imageHeight = 150,
    this.crossAxisCount = 3,
  });

  final String label;
  final List<String> galleryImages;
  final Function(int index, String imageUrl)? onImageTap;
  final Function(int index)? onDeleteImage;
  final double imageHeight;
  final int crossAxisCount;

  @override
  State<VenueImageGalleryWidget> createState() =>
      _VenueImageGalleryWidgetState();
}

class _VenueImageGalleryWidgetState extends State<VenueImageGalleryWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.galleryImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Gallery grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: widget.galleryImages.length,
          itemBuilder: (context, index) {
            final imageUrl = widget.galleryImages[index];
            return _buildGalleryImageTile(
              context,
              index,
              imageUrl,
              colorScheme,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGalleryImageTile(
    BuildContext context,
    int index,
    String imageUrl,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => widget.onImageTap?.call(index, imageUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Failed',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Overlay on hover/tap
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onImageTap?.call(index, imageUrl),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Delete button
              if (widget.onDeleteImage != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => widget.onDeleteImage?.call(index),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
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
