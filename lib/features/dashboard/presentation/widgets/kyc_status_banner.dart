import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../auth/domain/owner_auth_models.dart';

class KycStatusBanner extends StatelessWidget {
  const KycStatusBanner({
    super.key,
    required this.status,
    required this.rejectionReason,
    required this.hasUploadedAnyKycDocument,
    required this.onTap,
  });

  final KycVerificationStatus status;
  final String? rejectionReason;
  final bool hasUploadedAnyKycDocument;
  final VoidCallback onTap;

  bool get _isRejected => status == KycVerificationStatus.rejected;

  String get _title {
    if (_isRejected) return 'KYC Rejected';
    if (hasUploadedAnyKycDocument) return 'KYC Under Review';
    return 'Complete KYC Verification';
  }

  String get _subtitle {
    if (_isRejected) {
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty) {
        return 'Reason: ${rejectionReason!.trim()}';
      }
      return 'Your documents were not approved. Please update and resubmit.';
    }
    if (hasUploadedAnyKycDocument) {
      return 'Documents submitted. We will notify you once review is complete.';
    }
    return 'Upload required documents to unlock all features.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Light subtle background rather than harsh colors
    final containerColor = _isRejected
        ? colorScheme.errorContainer.withValues(alpha: 0.3)
        : colorScheme.primaryContainer.withValues(alpha: 0.3);
        
    final borderColor = _isRejected
        ? colorScheme.error.withValues(alpha: 0.2)
        : colorScheme.primary.withValues(alpha: 0.2);
        
    final iconColor = _isRejected ? colorScheme.error : colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRejected
                    ? Icons.error_outline_rounded
                    : Icons.hourglass_empty_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: AppFontWeights.semiBold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded, 
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
