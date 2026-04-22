import 'dart:io';

import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../media/presentation/widgets/refreshable_kyc_image_display.dart';
import '../../../media/presentation/widgets/uploaded_image_display.dart';

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
    final cs = Theme.of(context).colorScheme;
    switch (this) {
      case KycDocumentUploadStatus.notStarted:
        return KycDocumentStatusColors(
          backgroundColor: cs.surfaceContainerHighest,
          textColor: cs.onSurfaceVariant,
          iconColor: cs.onSurfaceVariant,
          borderColor: cs.outlineVariant,
        );
      case KycDocumentUploadStatus.uploading:
        return KycDocumentStatusColors(
          backgroundColor: cs.secondaryContainer,
          textColor: cs.onSecondaryContainer,
          iconColor: cs.onSecondaryContainer,
          borderColor: cs.secondary,
        );
      case KycDocumentUploadStatus.pending:
        return KycDocumentStatusColors(
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          textColor: AppColors.warning,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning.withValues(alpha: 0.45),
        );
      case KycDocumentUploadStatus.approved:
        return KycDocumentStatusColors(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          textColor: AppColors.success,
          iconColor: AppColors.success,
          borderColor: AppColors.success.withValues(alpha: 0.45),
        );
      case KycDocumentUploadStatus.rejected:
        return KycDocumentStatusColors(
          backgroundColor: cs.errorContainer,
          textColor: cs.onErrorContainer,
          iconColor: cs.onErrorContainer,
          borderColor: cs.error,
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

class KycDocumentCard extends StatelessWidget {
  const KycDocumentCard({
    super.key,
    required this.title,
    required this.description,
    required this.docType,
    required this.status,
    this.assetId,
    this.imageUrl,
    this.documentKey,
    this.imagePath,
    this.isLoading = false,
    this.uploadProgress,
    this.rejectionReason,
    this.onCameraPressed,
    this.onGalleryPressed,
    this.onRefreshImageUrl,
  });

  final String title;
  final String description;
  final String docType;
  final KycDocumentUploadStatus status;
  final String? assetId;
  final String? imageUrl;
  final String? documentKey;
  final String? imagePath;
  final bool isLoading;
  final double? uploadProgress;
  final String? rejectionReason;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onGalleryPressed;
  final Future<String> Function()? onRefreshImageUrl;

  Widget _getDocIllustration() {
    final assetPath = switch (docType) {
      'business_registration' => 'assets/kyc/company_registration.png',
      'citizenship' => 'assets/kyc/citizenship_card.png',
      'business_pan' => 'assets/kyc/pan_card.png',
      _ => '',
    };

    if (assetPath.isEmpty) {
      return const Icon(Icons.description_rounded, size: 24);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(assetPath, width: 32, height: 32, fit: BoxFit.cover),
    );
  }

  bool get _hasPreview =>
      (imagePath != null && imagePath!.isNotEmpty) ||
      (assetId != null && assetId!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (documentKey != null && documentKey!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final colors = status.colorScheme(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: _getDocIllustration()),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeights.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(
                            label: status == KycDocumentUploadStatus.notStarted
                                ? 'Action required'
                                : status.label,
                            backgroundColor: colors.backgroundColor,
                            textColor: colors.textColor,
                            borderColor: colors.borderColor,
                            icon: status.icon,
                          ),
                          if (status == KycDocumentUploadStatus.approved)
                            _StatusChip(
                              label: 'Uploaded',
                              backgroundColor: AppColors.success.withValues(
                                alpha: 0.1,
                              ),
                              textColor: AppColors.success,
                              borderColor: AppColors.success.withValues(
                                alpha: 0.25,
                              ),
                              icon: Icons.check_circle_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  status == KycDocumentUploadStatus.approved
                      ? Icons.verified_rounded
                      : Icons.chevron_right_rounded,
                  color: status == KycDocumentUploadStatus.approved
                      ? colors.borderColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (isLoading && uploadProgress != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: uploadProgress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colors.borderColor),
                ),
              ),
            ),
          if (rejectionReason != null && rejectionReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        rejectionReason!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (status != KycDocumentUploadStatus.notStarted && _hasPreview)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: _buildImageWidget(),
                ),
              ),
            ),
          if (status != KycDocumentUploadStatus.approved)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCameraPressed,
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onGalleryPressed,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: const Text('Gallery'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Use a clear, straight photo so the details stay readable.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if ((assetId != null && assetId!.isNotEmpty) ||
              (imageUrl != null && imageUrl!.isNotEmpty) ||
              (documentKey != null && documentKey!.isNotEmpty)) {
            return _buildNetworkImage();
          }
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 24,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }

    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    // Use RefreshableKycImageDisplay when refresh callback is available
    // to handle expired R2 presigned URLs automatically
    if (onRefreshImageUrl != null && imageUrl != null) {
      return RefreshableKycImageDisplay(
        downloadUrl: imageUrl!,
        docType: docType,
        onRefreshUrl: onRefreshImageUrl!,
        height: 132,
        width: double.infinity,
        fit: BoxFit.cover,
        borderRadius: 0,
      );
    }

    // Fallback to standard display for local images or when no refresh available
    return UploadedImageDisplay(
      assetId: assetId,
      image: imageUrl,
      cacheKey: documentKey,
      height: 132,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: AppFontWeights.semiBold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
