import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../media/controller/media_upload_controller.dart';
import '../../../media/model/media_upload_models.dart';
import '../../../media/service/media_upload_service.dart';
import '../../data/owner_auth_session_store.dart';
import '../../domain/owner_auth_models.dart';
import '../widgets/auth_header.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({
    super.key,
    this.state = ScreenUiState.content,
    this.onSubmitted,
  });

  final ScreenUiState state;
  final VoidCallback? onSubmitted;

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final MediaUploadController _mediaController =
      MediaUploadController(service: MediaUploadService());
  final OwnerAuthSessionStore _sessionStore = OwnerAuthSessionStore();
  final ImagePicker _imagePicker = ImagePicker();

  final Map<String, MediaUploadResult> _uploadedDocs =
      <String, MediaUploadResult>{};
  final Set<String> _pendingDocTypes = <String>{};
  Map<String, String> _existingKycDocKeys = const <String, String>{};
  KycVerificationStatus _kycStatus = KycVerificationStatus.pending;
  String? _kycRejectionReason;
  Owner? _owner;
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _loadOwnerId();
  }

  @override
  void dispose() {
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerId() async {
    final owner = await _sessionStore.getOwner();
    if (!mounted) {
      return;
    }
    setState(() {
      _owner = owner;
      _ownerId = owner?.id;
      _existingKycDocKeys = owner?.kycDocumentKeys ?? const <String, String>{};
      _kycStatus = owner?.kycStatus ?? KycVerificationStatus.pending;
      _kycRejectionReason = owner?.kycRejectionReason;
    });
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _pickAndUploadDocument({
    required OwnerKycDocType docType,
    required String title,
  }) async {
    final ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner session not found. Please log in again.')),
      );
      return;
    }

    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (selected == null) {
      return;
    }

    setState(() => _pendingDocTypes.add(docType.value));

    try {
      final bytes = await selected.readAsBytes();
      final uploaded = await _mediaController.uploadKycDocument(
        docType: docType,
        bytes: bytes,
        contentType: _guessContentType(selected.name),
      );

      if (!mounted) {
        return;
      }

      final updatedOwner = _owner?.copyWith(
        isKycApproved: false,
        kycStatus: KycVerificationStatus.pending,
        kycRejectionReason: null,
        kycDocumentKeys: {
          ..._existingKycDocKeys,
          docType.value: uploaded.key,
        },
      );
      if (updatedOwner != null) {
        await _sessionStore.saveOwner(updatedOwner);
      }
      await _sessionStore.saveKycDocKeyForOwner(
        ownerId: ownerId,
        docType: docType.value,
        storageKey: uploaded.key,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _uploadedDocs[docType.value] = uploaded;
        _owner = updatedOwner;
        _existingKycDocKeys = updatedOwner?.kycDocumentKeys ?? _existingKycDocKeys;
        _kycStatus = KycVerificationStatus.pending;
        _kycRejectionReason = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title uploaded successfully.')));
    } on Exception {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _mediaController.errorMessage ?? 'Unable to upload document.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingDocTypes.remove(docType.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const docs = [
      ('Business Registration', OwnerKycDocType.businessRegistration),
      ('Citizenship Document', OwnerKycDocType.citizenship),
      ('PAN Document', OwnerKycDocType.businessPan),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No required documents',
        emptySubtitle: 'UI placeholder for empty document list.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            const AuthHeader(
              title: 'KYC Verification',
              subtitle: 'Upload documents to complete your account verification',
            ),
            const SizedBox(height: AppSpacing.md),
            _KycOverviewCard(
              status: _kycStatus,
              rejectionReason: _kycRejectionReason,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Upload clear photos or scans of your documents',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Accepted formats: JPG, PNG, PDF\nFile size: Up to 5MB each',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Required Documents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...docs.map((doc) {
              final title = doc.$1;
              final docType = doc.$2;
              final upload = _uploadedDocs[docType.value];
                final existingKey = _existingKycDocKeys[docType.value];
                final isAlreadySubmitted =
                  existingKey != null && existingKey.trim().isNotEmpty;
                final isUploaded = upload != null || isAlreadySubmitted;
              final isLoading = _pendingDocTypes.contains(docType.value);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isUploaded
                                  ? Theme.of(context).colorScheme.tertiaryContainer
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                isUploaded
                                    ? Icons.check_circle
                                    : Icons.description_outlined,
                                color: isUploaded
                                    ? Theme.of(context).colorScheme.onTertiaryContainer
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isUploaded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          upload != null ? 'Uploaded' : 'Submitted',
                                          style:
                                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (!isUploaded)
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: Text(
                                      'Awaiting upload',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isUploaded) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Document ID',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                upload?.key ?? existingKey ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: isUploaded ? 'Re-upload' : 'Select & Upload',
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => _pickAndUploadDocument(
                                  docType: docType,
                                  title: title,
                                ),
                        variant: isUploaded
                            ? AppButtonVariant.outlined
                            : AppButtonVariant.filled,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Submit for review',
              onPressed: () {
                if (widget.onSubmitted != null) {
                  widget.onSubmitted!();
                  return;
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KycOverviewCard extends StatelessWidget {
  const _KycOverviewCard({
    required this.status,
    required this.rejectionReason,
  });

  final KycVerificationStatus status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isApproved = status == KycVerificationStatus.approved;
    final isRejected = status == KycVerificationStatus.rejected;

    final bgColor = isApproved
        ? colorScheme.tertiaryContainer
        : isRejected
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final fgColor = isApproved
        ? colorScheme.onTertiaryContainer
        : isRejected
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    final title = isApproved
        ? 'KYC Approved'
        : isRejected
        ? 'KYC Rejected'
        : 'KYC Pending';

    final subtitle = isApproved
        ? 'Your documents are approved. You can still update documents if needed.'
        : isRejected
        ? (rejectionReason != null && rejectionReason!.trim().isNotEmpty
              ? 'Reason: ${rejectionReason!.trim()}'
              : 'Your documents were not approved. Please upload corrected copies.')
        : 'Upload all required documents and submit for admin review.';

    final icon = isApproved
        ? Icons.verified_rounded
        : isRejected
        ? Icons.error_rounded
        : Icons.hourglass_top_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
