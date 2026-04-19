import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../media/controller/media_upload_controller.dart';
import '../../../media/model/media_upload_models.dart';
import '../../../media/service/media_upload_service.dart';
import '../../../media/service/uploaded_image_cache.dart';
import '../../data/kyc_documents_service.dart';
import '../../data/owner_auth_session_store.dart';
import '../../domain/owner_auth_models.dart';
import '../widgets/kyc_document_card.dart';

// ============================================================================
// KYC Verification Screen (Redesigned Wizard)
// professional step-by-step UI with focus states
// ============================================================================

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({
    super.key,
    this.state = ScreenUiState.content,
    this.onSubmitted,
  });

  final ScreenUiState state;
  final VoidCallback? onSubmitted;

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  late MediaUploadController _mediaController;
  // ignore: unused_field
  late KycDocumentsService _kycDocsService;
  final OwnerAuthSessionStore _sessionStore = OwnerAuthSessionStore();
  final ImagePicker _imagePicker = ImagePicker();

  Owner? _owner;

  // Track upload states
  final Map<String, _DocumentState> _documentStates =
      <String, _DocumentState>{};

  // Track which tile is currently expanded
  String? _focusedDocType;

  @override
  void initState() {
    super.initState();
    _mediaController = MediaUploadController(service: MediaUploadService());
    _kycDocsService = KycDocumentsService();
    _initializeDocumentStates();
    _loadOwnerData();
  }

  void _initializeDocumentStates() {
    const docTypes = ['business_registration', 'citizenship', 'business_pan'];
    for (final docType in docTypes) {
      _documentStates[docType] = _DocumentState(
        docType: docType,
        status: KycDocumentUploadStatus.notStarted,
      );
    }
  }

  @override
  void dispose() {
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerData() async {
    final owner = await _sessionStore.getOwner();
    if (!mounted) return;

    setState(() {
      _owner = owner;

      // Update document states based on owner's KYC data
      for (final entry in
          owner?.kycDocumentKeys.entries ??
          const <MapEntry<String, String>>[]) {
        final docType = entry.key;
        final docKey = entry.value;

        if (_documentStates.containsKey(docType)) {
          _documentStates[docType] = _DocumentState(
            docType: docType,
            status: _getDocumentStatus(owner),
            documentKey: docKey,
          );
        }
      }
      
      // Auto-focus first incomplete doc
      _autoFocusNext();
    });
  }

  void _autoFocusNext() {
    for (final entry in _documentStates.entries) {
      if (entry.value.status == KycDocumentUploadStatus.notStarted ||
          entry.value.status == KycDocumentUploadStatus.rejected) {
        _focusedDocType = entry.key;
        return;
      }
    }
    _focusedDocType = null;
  }

  KycDocumentUploadStatus _getDocumentStatus(Owner? owner) {
    if (owner == null) return KycDocumentUploadStatus.notStarted;

    switch (owner.kycStatus) {
      case KycVerificationStatus.approved:
        return KycDocumentUploadStatus.approved;
      case KycVerificationStatus.rejected:
        return KycDocumentUploadStatus.rejected;
      case KycVerificationStatus.pending:
        // Even if overall is pending, we can treat individual already uploaded docs as pending review or approved mock
        // For UI purposes, let's treat them as approved visually if they are uploaded and not rejected,
        // so they turn green. Or we can keep them pending (blue/yellow).
        // Let's use approved to give the green checkmark effect requested.
        return KycDocumentUploadStatus.approved;
    }
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickAndUploadDocument({
    required String docType,
    required String title,
    required ImageSource source,
  }) async {
    final selected = await _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (selected == null) return;

    final bytes = await selected.readAsBytes();
    final tempAssetId =
        'temp_${docType}_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _documentStates[docType] = _DocumentState(
        docType: docType,
        status: KycDocumentUploadStatus.uploading,
        imagePath: selected.path,
        assetId: tempAssetId,
      );
    });

    try {
      final uploadedImageCache = UploadedImageCache();
      uploadedImageCache.save(
        assetId: tempAssetId,
        key: '',
        imageBytes: bytes,
      );

      final uploaded = await _mediaController.uploadKycDocument(
        docType: _parseDocType(docType),
        bytes: bytes,
        contentType: _guessContentType(selected.name),
        pollUntilReady: true,
      );

      if (!mounted) return;

      final updatedOwner = _owner?.copyWith(
        isKycApproved: false,
        kycStatus: KycVerificationStatus.pending,
        kycRejectionReason: null,
        kycDocumentKeys: {
          ...(_owner?.kycDocumentKeys ?? {}),
          docType: uploaded.key,
        },
      );

      if (updatedOwner != null) {
        await _sessionStore.saveOwner(updatedOwner);
      }

      if (!mounted) return;

      setState(() {
        _owner = updatedOwner;
        _documentStates[docType] = _DocumentState(
          docType: docType,
          status: KycDocumentUploadStatus.approved, // Mark approved visually for the flow
          documentKey: uploaded.key,
          assetId: uploaded.assetId,
          imagePath: selected.path,
        );
        _autoFocusNext();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title uploaded successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _documentStates[docType] = _DocumentState(
          docType: docType,
          status: KycDocumentUploadStatus.notStarted,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: ${_mediaController.errorMessage ?? 'Unknown error'}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  OwnerKycDocType _parseDocType(String docType) {
    if (docType == 'citizenship') return OwnerKycDocType.citizenship;
    if (docType == 'business_registration') {
      return OwnerKycDocType.businessRegistration;
    }
    return OwnerKycDocType.businessPan;
  }

  String _getDocumentTitle(String docType) {
    if (docType == 'business_registration') return 'Business Registration';
    if (docType == 'citizenship') return 'Citizenship Document';
    return 'Business PAN Document';
  }

  String _getDocumentDescription(String docType) {
    if (docType == 'business_registration') return 'Company registration certificate';
    if (docType == 'citizenship') return "Owner's citizenship card or passport";
    return 'Business PAN card';
  }

  int get _completedCount => _documentStates.values
      .where((s) => s.status == KycDocumentUploadStatus.approved || s.status == KycDocumentUploadStatus.pending)
      .length;

  bool get _allCompleted => _completedCount == 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinalScreen = _allCompleted;
    
    return Scaffold(
      appBar: AppBar(
        leading: isFinalScreen ? const SizedBox.shrink() : const BackButton(),
        title: Text(isFinalScreen ? 'Verification Complete!' : 'Get Verified for Full Access'),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'KYC Verification',
        emptySubtitle: 'Load your KYC documents',
        content: CustomScrollView(
          slivers: [
            // Header Progress Area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isFinalScreen) ...[
                      Text(
                        '$_completedCount of 3 docs completed.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeights.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _completedCount / 3,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildEncouragingMessage(theme),
                    ] else ...[
                      _buildSuccessMessage(theme),
                    ],
                  ],
                ),
              ),
            ),
            
            // Document Tiles
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final docType = _documentStates.keys.toList()[index];
                final state = _documentStates[docType]!;
                final isFocused = _focusedDocType == docType;
                final isDimmed = _focusedDocType != null && !isFocused && !isFinalScreen;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg) +
                      const EdgeInsets.only(bottom: AppSpacing.md),
                  child: KycDocumentCard(
                    title: _getDocumentTitle(docType),
                    description: _getDocumentDescription(docType),
                    docType: docType,
                    status: state.status,
                    assetId: state.assetId,
                    imagePath: state.imagePath,
                    isFocused: isFocused,
                    isDimmed: isDimmed,
                    isLoading:
                        _mediaController.isUploading &&
                        _documentStates.keys.elementAt(index) == docType,
                    uploadProgress: _mediaController.progress,
                    onTap: () {
                      setState(() {
                         _focusedDocType = isFocused ? null : docType;
                      });
                    },
                    onCameraPressed: () => _pickAndUploadDocument(
                      docType: docType,
                      title: _getDocumentTitle(docType),
                      source: ImageSource.camera,
                    ),
                    onGalleryPressed: () => _pickAndUploadDocument(
                      docType: docType,
                      title: _getDocumentTitle(docType),
                      source: ImageSource.gallery,
                    ),
                    rejectionReason: _owner?.kycRejectionReason,
                  ),
                );
              }, childCount: _documentStates.length),
            ),

            // Submit Button appearing only when finished
            if (isFinalScreen)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    label: 'Submit Full KYC & Back to Dashboard',
                    onPressed: () {
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!();
                        return;
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
            // Or the submit all CTA
            else if (_completedCount > 0 && _completedCount < 3)
              SliverToBoxAdapter(
                 child: const SizedBox(height: 100), // Padding for scrolling
              )
          ],
        ),
      ),
    );
  }

  Widget _buildEncouragingMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_open_rounded, color: theme.colorScheme.onPrimary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Complete verification to unlock unlimited court bookings and revenue analytics.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
           Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.celebration_rounded, color: theme.colorScheme.onTertiary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Your verification is underway! All documents have been uploaded successfully.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentState {
  _DocumentState({
    required this.docType,
    required this.status,
    this.documentKey,
    this.assetId,
    this.imagePath,
  });

  final String docType;
  final KycDocumentUploadStatus status;
  final String? documentKey;
  final String? assetId;
  final String? imagePath;
}
