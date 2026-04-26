import 'dart:io';

import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/app_spacing.dart';


// ============================================================================
// VenueImageUploadWidget
// Beautiful UI for venue image selection with instant preview and upload
// ============================================================================

class VenueImageUploadWidget extends StatefulWidget {
  const VenueImageUploadWidget({
    super.key,
    required this.label,
    required this.hint,
    this.width = double.infinity,
    this.height = 200,
    this.selectedImagePath,
    this.uploadedImageUrl,
    this.onImageSelected,
    this.onUploadStarted,
    this.onUploadProgress,
    this.onUploadComplete,
    this.onUploadError,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadStatusMessage,
  });

  final String label;
  final String hint;
  final double width;
  final double height;
  final String? selectedImagePath;
  final String? uploadedImageUrl;
  final Function(XFile file)? onImageSelected;
  final VoidCallback? onUploadStarted;
  final Function(double progress)? onUploadProgress;
  final VoidCallback? onUploadComplete;
  final Function(String error)? onUploadError;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadStatusMessage;

  @override
  State<VenueImageUploadWidget> createState() =>
      _VenueImageUploadWidgetState();
}

class _VenueImageUploadWidgetState extends State<VenueImageUploadWidget> {
  late ImagePicker _imagePicker;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked != null) {
      widget.onImageSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelectedImage = widget.selectedImagePath != null;
    final hasUploadedImage = widget.uploadedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: AppFontWeights.semiBold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Hint text
        Text(
          widget.hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Image preview or upload button
        if (!hasSelectedImage && !hasUploadedImage)
          _buildUploadPrompt(context, colorScheme)
        else if (hasSelectedImage)
          _buildSelectedImagePreview(context, colorScheme)
        else if (hasUploadedImage)
          _buildUploadedImagePreview(context, colorScheme),

        // Upload progress indicator
        if (widget.isUploading) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildUploadProgressSection(context),
        ],

        // Status message
        if (widget.uploadStatusMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.uploadStatusMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadPrompt(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: widget.isUploading ? null : _pickImage,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Material(
          color: colorScheme.surface.withValues(alpha: 0),
          child: InkWell(
            onTap: widget.isUploading ? null : _pickImage,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Choose Image',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: AppFontWeights.semiBold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap to select from gallery',
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

  Widget _buildSelectedImagePreview(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.file(
              File(widget.selectedImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Failed to load image',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Overlay with action button
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.scrim.withValues(alpha: 0.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.isUploading ? null : _pickImage,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Change Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.onPrimary,
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ready to upload',
                  style: TextStyle(
                    color: colorScheme.onTertiary,
                    fontWeight: AppFontWeights.semiBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImagePreview(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _showFullPreview(context),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                widget.uploadedImageUrl!,
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
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Failed to load image',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Success badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                      color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                      children: [
                      Icon(Icons.check_rounded,
                            size: 14, color: colorScheme.onPrimary),
                        const SizedBox(width: 4),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                            color: colorScheme.onPrimary,
                          fontWeight: AppFontWeights.semiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // View hint overlay
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full_rounded,
                          size: 12, color: colorScheme.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'View',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: AppFontWeights.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploading',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                  ),
            ),
            Text(
              '${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.uploadProgress,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  void _showFullPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              widget.uploadedImageUrl!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
