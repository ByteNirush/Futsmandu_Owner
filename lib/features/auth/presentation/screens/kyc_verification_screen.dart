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
import '../widgets/auth_header.dart';
import '../widgets/kyc_document_card.dart';

// ============================================================================
// KYC Verification Screen (Improved)
// Professional KYC UI with instant document preview and status tracking
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
  late KycDocumentsService _kycDocsService;
  final OwnerAuthSessionStore _sessionStore = OwnerAuthSessionStore();
  final ImagePicker _imagePicker = ImagePicker();

  Owner? _owner;

  // Track upload states
  final Map<String, _DocumentState> _documentStates =
      <String, _DocumentState>{};

  // Track fetched signed URLs for private KYC documents
  final Map<String, String> _signedUrls = <String, String>{};

  @override
  void initState() {
    super.initState();
    _mediaController = MediaUploadController(service: MediaUploadService());
    _kycDocsService = KycDocumentsService();
    _initializeDocumentStates();
    _loadOwnerData();
  }

  void _initializeDocumentStates() {
    const docTypes = ['citizenship', 'business_registration', 'business_pan'];
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
    });

    // Fetch signed URLs for existing documents
    if (owner != null && owner.kycDocumentKeys.isNotEmpty) {
      _fetchSignedUrls(owner.kycDocumentKeys.values.toList());
    }
  }

  Future<void> _fetchSignedUrls(List<String> documentKeys) async {
    try {
      final urls = await _kycDocsService.getKycDocumentsUrls(documentKeys);
      if (!mounted) return;
      setState(() => _signedUrls.addAll(urls.cast<String, String>()));
    } catch (e) {
      // Silently fail - signed URLs are optional for preview
    }
  }

  KycDocumentUploadStatus _getDocumentStatus(Owner? owner) {
    if (owner == null) return KycDocumentUploadStatus.notStarted;

    switch (owner.kycStatus) {
      case KycVerificationStatus.approved:
        return KycDocumentUploadStatus.approved;
      case KycVerificationStatus.rejected:
        return KycDocumentUploadStatus.rejected;
      case KycVerificationStatus.pending:
        return KycDocumentUploadStatus.pending;
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
  }) async {
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (selected == null) return;

    final bytes = await selected.readAsBytes();

    // Create a temporary assetId for instant preview caching
    // This allows the image to show immediately while upload is in progress
    final tempAssetId =
        'temp_${docType}_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _documentStates[docType] = _DocumentState(
        docType: docType,
        status: KycDocumentUploadStatus.uploading,
        imagePath: selected.path,
        assetId: tempAssetId, // Show temporary preview immediately
      );
    });

    try {
      // Import this at the top of file if not already there
      // Import UploadedImageCache for immediate caching
      final uploadedImageCache = UploadedImageCache();

      // Cache the image immediately for instant preview display
      // This creates a base64 data URL that shows instantly
      uploadedImageCache.save(
        assetId: tempAssetId,
        key: '', // Temporary, will be replaced after upload
        imageBytes: bytes,
      );

      final uploaded = await _mediaController.uploadKycDocument(
        docType: _parseDocType(docType),
        bytes: bytes,
        contentType: _guessContentType(selected.name),
        pollUntilReady: true, // ✅ Wait for processing so image appears in API list
      );

      if (!mounted) return;

      // Update owner with new document
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
          status: KycDocumentUploadStatus.pending,
          documentKey: uploaded.key,
          assetId: uploaded.assetId,
          imagePath: selected.path, // Keep the path for future reference
        );
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
    if (docType == 'citizenship') return 'Citizenship Document';
    if (docType == 'business_registration') return 'Business Registration';
    return 'Business PAN';
  }

  String _getDocumentDescription(String docType) {
    if (docType == 'citizenship') {
      return 'Clear copy of your citizenship/national ID';
    }
    if (docType == 'business_registration') {
      return 'Business registration or incorporation document';
    }
    return 'Business PAN or tax identification number';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'KYC Verification',
        emptySubtitle: 'Load your KYC documents',
        content: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthHeader(
                      title: 'KYC Verification',
                      subtitle:
                          'Upload your documents to complete account verification',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatusOverview(),
                  ],
                ),
              ),
            ),

            // Instructions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildInstructions(context),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // Document Cards
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final docType = _documentStates.keys.toList()[index];
                final state = _documentStates[docType]!;

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
                    isLoading:
                        _mediaController.isUploading &&
                        _documentStates.keys.elementAt(index) == docType,
                    uploadProgress: _mediaController.progress,
                    onUploadPressed: () => _pickAndUploadDocument(
                      docType: docType,
                      title: _getDocumentTitle(docType),
                    ),
                    rejectionReason: _owner?.kycRejectionReason,
                  ),
                );
              }, childCount: _documentStates.length),
            ),

            // Submit Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'Submit for Review',
                      onPressed:
                          _owner != null && _owner!.hasUploadedAllKycDocuments
                          ? () {
                              if (widget.onSubmitted != null) {
                                widget.onSubmitted!();
                                return;
                              }
                              Navigator.pop(context);
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _owner != null && !_owner!.hasUploadedAllKycDocuments
                          ? 'Upload all documents to submit'
                          : 'All documents uploaded',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverview() {
    final owner = _owner;
    if (owner == null) {
      return const SizedBox.shrink();
    }

    final isApproved = owner.kycStatus == KycVerificationStatus.approved;
    final isRejected = owner.kycStatus == KycVerificationStatus.rejected;

    Color bgColor;
    Color fgColor;
    IconData icon;
    String title;
    String subtitle;

    if (isApproved) {
      bgColor = Theme.of(context).colorScheme.tertiaryContainer;
      fgColor = Theme.of(context).colorScheme.onTertiaryContainer;
      icon = Icons.verified_rounded;
      title = '✓ KYC Approved';
      subtitle = 'Your account is fully verified';
    } else if (isRejected) {
      bgColor = Theme.of(context).colorScheme.errorContainer;
      fgColor = Theme.of(context).colorScheme.onErrorContainer;
      icon = Icons.error_rounded;
      title = '✗ KYC Rejected';
      subtitle = owner.kycRejectionReason ?? 'Please re-submit documents';
    } else {
      bgColor = const Color(0xFFFFF8E1);
      fgColor = const Color(0xFFF57F17);
      icon = Icons.hourglass_top_rounded;
      title = '⏳ KYC Pending';
      subtitle = owner.hasUploadedAnyKycDocument
          ? 'Your documents are under review'
          : 'Upload your documents to get started';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: fgColor,
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: fgColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Document Requirements',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: AppFontWeights.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _instructionItem(context, '• Clear, well-lit photos or scans'),
          _instructionItem(context, '• All four corners must be visible'),
          _instructionItem(context, '• JPG, PNG, or PDF format'),
          _instructionItem(context, '• Maximum 5MB per document'),
        ],
      ),
    );
  }

  Widget _instructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// Helper class to track document upload state
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
