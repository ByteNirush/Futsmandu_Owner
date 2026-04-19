import 'dart:io';

import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../media/presentation/widgets/uploaded_image_display.dart';

// ============================================================================
// KYC Document Status Enum & Extensions
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
    switch (this) {
      case KycDocumentUploadStatus.notStarted:
        return KycDocumentStatusColors(
          backgroundColor: const Color(0xFFFFF3E0), // Orange 50 (light)
          textColor: const Color(0xFFE65100), // Orange 900
          iconColor: const Color(0xFFE65100),
          borderColor: const Color(0xFFFF9800), // Orange 500
        );
      case KycDocumentUploadStatus.uploading:
        return KycDocumentStatusColors(
          backgroundColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          iconColor: const Color(0xFF1565C0),
          borderColor: const Color(0xFF2196F3),
        );
      case KycDocumentUploadStatus.pending:
        return KycDocumentStatusColors(
          backgroundColor: const Color(0xFFFFF8E1),
          textColor: const Color(0xFFF57F17),
          iconColor: const Color(0xFFF57F17),
          borderColor: const Color(0xFFFFC107),
        );
      case KycDocumentUploadStatus.approved:
        return KycDocumentStatusColors(
          backgroundColor: const Color(0xFFE8F5E9), // Green 50
          textColor: const Color(0xFF1B5E20), // Green 900
          iconColor: const Color(0xFF1B5E20),
          borderColor: const Color(0xFF4CAF50), // Green 500
        );
      case KycDocumentUploadStatus.rejected:
        return KycDocumentStatusColors(
          backgroundColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFB71C1C),
          iconColor: const Color(0xFFB71C1C),
          borderColor: const Color(0xFFF44336),
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
// KYC Document Card (Tile Redesign)
// ============================================================================

class KycDocumentCard extends StatelessWidget {
  const KycDocumentCard({
    super.key,
    required this.title,
    required this.description,
    required this.docType,
    required this.status,
    this.assetId,
    this.imagePath,
    this.isLoading = false,
    this.uploadProgress,
    this.rejectionReason,
    required this.isFocused,
    required this.isDimmed,
    required this.onTap,
    this.onCameraPressed,
    this.onGalleryPressed,
  });

  final String title;
  final String description;
  final String docType;
  final KycDocumentUploadStatus status;
  final String? assetId;
  final String? imagePath;
  final bool isLoading;
  final double? uploadProgress;
  final String? rejectionReason;
  
  final bool isFocused;
  final bool isDimmed;
  final VoidCallback onTap;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onGalleryPressed;

  Widget _getDocIllustration() {
    String assetPath;
    if (docType == 'business_registration') {
      assetPath = 'assets/kyc/company_registration.png';
    } else if (docType == 'citizenship') {
      assetPath = 'assets/kyc/citizenship_card.png';
    } else if (docType == 'business_pan') {
      assetPath = 'assets/kyc/pan_card.png';
    } else {
       return const Icon(Icons.description_rounded, size: 28);
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        assetPath,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = status.colorScheme(context);
    final theme = Theme.of(context);
    
    // Dimming logic
    final opacity = isDimmed ? 0.4 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: GestureDetector(
        onTap: isDimmed ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isFocused ? colors.backgroundColor.withValues(alpha: 0.1) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused || status == KycDocumentUploadStatus.approved 
                    ? colors.borderColor 
                    : theme.colorScheme.outlineVariant,
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isFocused ? [
              BoxShadow(
                color: colors.borderColor.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Tile Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Miniature Document Illustration
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: _getDocIllustration(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    
                    // Title and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: AppFontWeights.bold,
                              color: status == KycDocumentUploadStatus.approved 
                                  ? colors.borderColor 
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (status == KycDocumentUploadStatus.approved) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.backgroundColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 12, color: colors.iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Approved',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.iconColor,
                                      fontWeight: AppFontWeights.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ] else if (status != KycDocumentUploadStatus.notStarted && status != KycDocumentUploadStatus.uploading) ...[
                             const SizedBox(height: 4),
                             Text(
                               status.label,
                               style: theme.textTheme.labelSmall?.copyWith(
                                 color: colors.iconColor,
                                 fontWeight: AppFontWeights.bold,
                               ),
                             ),
                          ] else if (status == KycDocumentUploadStatus.notStarted) ...[
                             const SizedBox(height: 4),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: colors.backgroundColor.withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
                               ),
                               child: Text(
                                 'Action Required',
                                 style: theme.textTheme.labelSmall?.copyWith(
                                   color: colors.iconColor,
                                   fontWeight: AppFontWeights.bold,
                                 ),
                               ),
                             )
                          ]
                        ],
                      ),
                    ),
                    
                    // Interaction Indicator
                    if (status != KycDocumentUploadStatus.approved)
                      Icon(
                        isFocused ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    else 
                      Icon(Icons.check_circle_rounded, color: colors.iconColor, size: 32),
                  ],
                ),
              ),

              // Uploading Progress Indicator
              if (isLoading && uploadProgress != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: uploadProgress,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(colors.borderColor),
                    ),
                  ),
                ),

              // Rejection Reason
              if (rejectionReason != null && rejectionReason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
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

              // Expanded Focus Area (Action Circles & Preview)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
                child: isFocused && status != KycDocumentUploadStatus.approved && !isLoading
                  ? _buildExpandedActionArea(context)
                  : const SizedBox.shrink(),
              ),
              
              // Show preview if already uploaded but pending
              if (!isFocused && (status == KycDocumentUploadStatus.pending) && (imagePath != null || assetId != null))
                 _buildSmallPreview(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedActionArea(BuildContext context) {
    final theme = Theme.of(context);
    final colors = status.colorScheme(context);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
           top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionCircle(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  subtext: '(Front)',
                  color: colors.borderColor,
                  onTap: onCameraPressed ?? () {},
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ActionCircle(
                  icon: Icons.upload_file_rounded,
                  label: 'Choose File',
                  subtext: '(PDF, JPG)',
                  color: colors.borderColor,
                  onTap: onGalleryPressed ?? () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ensure all details are readable. Good lighting, flat surface.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildSmallPreview(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: SizedBox(
          height: 120,
          child: ClipRRect(
             borderRadius: BorderRadius.circular(8),
             child: _buildImageWidget(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageWidget() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (assetId != null && assetId!.isNotEmpty) {
            return UploadedImageDisplay(
              assetId: assetId,
              height: 120,
              width: 180,
              fit: BoxFit.cover,
              borderRadius: 0,
            );
          }
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
            ),
          );
        },
      );
    }
    return UploadedImageDisplay(
      assetId: assetId,
      height: 120,
      width: 180,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.subtext,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtext;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: AppFontWeights.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              subtext,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
