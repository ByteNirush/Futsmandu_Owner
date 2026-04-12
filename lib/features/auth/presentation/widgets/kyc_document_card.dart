import 'dart:io';

import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../media/presentation/widgets/uploaded_image_display.dart';

// ============================================================================
// KYC Document Status Indicator
// ============================================================================

class KycDocumentStatusBadge extends StatelessWidget {
  const KycDocumentStatusBadge({
    super.key,
    required this.status,
  });

  final KycDocumentUploadStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = status.colorScheme(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: colors.iconColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.textColor,
              fontWeight: AppFontWeights.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// KYC Document Status Enum
// ============================================================================

enum KycDocumentUploadStatus {
  notStarted,
  uploading,
  pending,
  approved,
  rejected,
}

extension KycDocumentStatusExtension on KycDocumentUploadStatus {
  String get label {
    switch (this) {
      case KycDocumentUploadStatus.notStarted:
        return 'Not Started';
      case KycDocumentUploadStatus.uploading:
        return 'Uploading...';
      case KycDocumentUploadStatus.pending:
        return 'Pending Review';
      case KycDocumentUploadStatus.approved:
        return 'Approved';
      case KycDocumentUploadStatus.rejected:
        return 'Rejected';
    }
  }

  IconData get icon {
    switch (this) {
      case KycDocumentUploadStatus.notStarted:
        return Icons.cloud_upload_outlined;
      case KycDocumentUploadStatus.uploading:
        return Icons.cloud_sync;
      case KycDocumentUploadStatus.pending:
        return Icons.hourglass_top;
      case KycDocumentUploadStatus.approved:
        return Icons.verified;
      case KycDocumentUploadStatus.rejected:
        return Icons.error;
    }
  }

  KycDocumentStatusColors colorScheme(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (this) {
      case KycDocumentUploadStatus.notStarted:
        return KycDocumentStatusColors(
          backgroundColor: colors.primaryContainer,
          textColor: colors.onPrimaryContainer,
          iconColor: colors.onPrimaryContainer,
          borderColor: colors.primary,
        );
      case KycDocumentUploadStatus.uploading:
        return KycDocumentStatusColors(
          backgroundColor: colors.primaryContainer,
          textColor: colors.onPrimaryContainer,
          iconColor: colors.onPrimaryContainer,
          borderColor: colors.primary,
        );
      case KycDocumentUploadStatus.pending:
        return KycDocumentStatusColors(
          backgroundColor: const Color(0xFFFFF8E1),
          textColor: const Color(0xFFF57F17),
          iconColor: const Color(0xFFF57F17),
          borderColor: const Color(0xFFFFB300),
        );
      case KycDocumentUploadStatus.approved:
        return KycDocumentStatusColors(
          backgroundColor: colors.tertiaryContainer,
          textColor: colors.onTertiaryContainer,
          iconColor: colors.onTertiaryContainer,
          borderColor: colors.tertiary,
        );
      case KycDocumentUploadStatus.rejected:
        return KycDocumentStatusColors(
          backgroundColor: colors.errorContainer,
          textColor: colors.onErrorContainer,
          iconColor: colors.onErrorContainer,
          borderColor: colors.error,
        );
    }
  }
}

class KycDocumentStatusColors {
  KycDocumentStatusColors({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.borderColor,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;
}

// ============================================================================
// KYC Document Card with Preview
// ============================================================================

class KycDocumentCard extends StatefulWidget {
  const KycDocumentCard({
    super.key,
    required this.title,
    required this.description,
    required this.docType,
    required this.status,
    this.assetId,
    this.imagePath,
    this.onUploadPressed,
    this.onViewPressed,
    this.isLoading = false,
    this.uploadProgress,
    this.rejectionReason,
  });

  final String title;
  final String description;
  final String docType;
  final KycDocumentUploadStatus status;
  final String? assetId;
  final String? imagePath;
  final VoidCallback? onUploadPressed;
  final VoidCallback? onViewPressed;
  final bool isLoading;
  final double? uploadProgress;
  final String? rejectionReason;

  @override
  State<KycDocumentCard> createState() => _KycDocumentCardState();
}

class _KycDocumentCardState extends State<KycDocumentCard> {
  bool _showPreview = true;

  @override
  Widget build(BuildContext context) {
    final hasPreview = widget.assetId != null || widget.imagePath != null;
    final showPreviewArea = _showPreview && hasPreview;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: AppFontWeights.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    KycDocumentStatusBadge(status: widget.status),
                  ],
                ),
                if (widget.rejectionReason != null && 
                    widget.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            widget.rejectionReason!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Preview Section
          if (showPreviewArea)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: _buildPreview(),
            ),

          // Actions and Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Progress
                if (widget.isLoading && widget.uploadProgress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.uploadProgress,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${(widget.uploadProgress! * 100).toStringAsFixed(0)}% uploaded',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: widget.status == KycDocumentUploadStatus.notStarted
                            ? 'Upload Document'
                            : 'Change Document',
                        onPressed: widget.isLoading ? null : widget.onUploadPressed,
                        isPrimary: true,
                      ),
                    ),
                    if (hasPreview) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          label: _showPreview ? 'Hide Preview' : 'Show Preview',
                          onPressed: widget.isLoading
                              ? null
                              : () {
                                setState(() => _showPreview = !_showPreview);
                              },
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Document Preview',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: AppFontWeights.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 240,
                maxWidth: 300,
              ),
              color: Theme.of(context).colorScheme.surface,
              child: _buildImageWidget(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap to expand',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    // First try to use imagePath if available (local file preview)
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.file(
        File(widget.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to assetId cache if file fails to load
          if (widget.assetId != null && widget.assetId!.isNotEmpty) {
            return UploadedImageDisplay(
              assetId: widget.assetId,
              height: 240,
              width: 300,
              fit: BoxFit.cover,
              borderRadius: 0,
            );
          }
          // Final fallback to placeholder
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            ),
          );
        },
      );
    }

    // Fallback to assetId-based display (cached image or CDN)
    return UploadedImageDisplay(
      assetId: widget.assetId,
      height: 240,
      width: 300,
      fit: BoxFit.cover,
      borderRadius: 0,
      placeholder: Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        child: widget.isLoading
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(label),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }
  }
}
