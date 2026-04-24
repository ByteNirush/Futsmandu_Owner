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
  final OwnerAuthSessionStore _sessionStore = OwnerAuthSessionStore();
  final ImagePicker _imagePicker = ImagePicker();

  Owner? _owner;

  // Track upload states
  final Map<String, _DocumentState> _documentStates =
      <String, _DocumentState>{};

  @override
  void initState() {
    super.initState();
    _mediaController = MediaUploadController(service: MediaUploadService());
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
    Map<String, KycDocumentItem> existingDocsByType =
        <String, KycDocumentItem>{};

    try {
      final response = await _mediaController.fetchAllKycDocuments();
      existingDocsByType = {
        for (final doc in response.documents)
          if (doc.docType.isNotEmpty) doc.docType: doc,
      };
    } catch (_) {
      existingDocsByType = <String, KycDocumentItem>{};
    }

    if (!mounted) return;

    setState(() {
      _owner = owner;

      for (final docType in _documentStates.keys) {
        final docKey = owner?.kycDocumentKeys[docType];
        final existingDoc = existingDocsByType[docType];
        final hasUploadedDoc =
            (docKey != null && docKey.isNotEmpty) || existingDoc != null;

        _documentStates[docType] = _DocumentState(
          docType: docType,
          status: hasUploadedDoc
              ? (owner == null
                    ? KycDocumentUploadStatus.pending
                    : _getDocumentStatus(owner))
              : KycDocumentUploadStatus.notStarted,
          documentKey: (docKey != null && docKey.isNotEmpty) ? docKey : null,
          assetId: existingDoc?.assetId,
          imageUrl: existingDoc?.downloadUrl,
        );
      }
    });
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
      uploadedImageCache.save(assetId: tempAssetId, key: '', imageBytes: bytes);

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
        final uploadStatus = uploaded.status;
        final nextStatus = uploadStatus.isFailed
            ? KycDocumentUploadStatus.rejected
            : KycDocumentUploadStatus.pending;

        _documentStates[docType] = _DocumentState(
          docType: docType,
          status: nextStatus,
          documentKey: uploaded.key,
          assetId: uploaded.assetId,
          imageUrl: uploaded.cdnUrl,
          imagePath: selected.path,
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
    if (docType == 'business_registration') return 'Business Registration';
    if (docType == 'citizenship') return 'Citizenship Document';
    return 'Business PAN Document';
  }

  /// Fetches fresh KYC documents and returns the updated download URL for the specific docType.
  /// Called when the R2 presigned URL expires (403 error) to get a fresh URL.
  Future<String> _refreshDocumentUrl(String docType) async {
    try {
      final response = await _mediaController.fetchAllKycDocuments();

      // Find the document for this docType
      final doc = response.documents.firstWhere(
        (d) => d.docType == docType,
        orElse: () => throw Exception('Document not found'),
      );

      if (doc.downloadUrl.isEmpty) {
        throw Exception('No download URL available');
      }

      // Update local state with the fresh URL
      if (mounted) {
        setState(() {
          final currentState = _documentStates[docType];
          if (currentState != null) {
            _documentStates[docType] = _DocumentState(
              docType: docType,
              status: currentState.status,
              documentKey: doc.assetId, // key is the assetId from backend
              assetId: doc.assetId,
              imageUrl: doc.downloadUrl,
              imagePath: currentState.imagePath,
            );
          }
        });
      }

      return doc.downloadUrl;
    } catch (e) {
      throw Exception('Failed to refresh document URL: $e');
    }
  }

  String _getDocumentDescription(String docType) {
    if (docType == 'business_registration') {
      return 'Company registration certificate';
    }
    if (docType == 'citizenship') return "Owner's citizenship card or passport";
    return 'Business PAN card';
  }

  int get _completedCount => _documentStates.values
      .where(
        (s) =>
            s.status == KycDocumentUploadStatus.approved ||
            s.status == KycDocumentUploadStatus.pending,
      )
      .length;

  bool get _allCompleted => _completedCount == 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinalScreen = _allCompleted;
    final canSubmit = _completedCount > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          isFinalScreen ? 'Verification complete' : 'KYC Verification',
        ),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildHeader(theme, isFinalScreen)],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Required Documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontWeights.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final docType = _documentStates.keys.toList()[index];
                final state = _documentStates[docType]!;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: KycDocumentCard(
                    title: _getDocumentTitle(docType),
                    description: _getDocumentDescription(docType),
                    docType: docType,
                    status: state.status,
                    assetId: state.assetId,
                    imageUrl: state.imageUrl,
                    documentKey: state.documentKey,
                    imagePath: state.imagePath,
                    isLoading:
                        _mediaController.isUploading &&
                        _documentStates.keys.elementAt(index) == docType,
                    uploadProgress: _mediaController.progress,
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
                    onRefreshImageUrl: () => _refreshDocumentUrl(docType),
                    rejectionReason: _owner?.kycRejectionReason,
                  ),
                );
              }, childCount: _documentStates.length),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(
        context,
        theme: theme,
        isFinalScreen: isFinalScreen,
        canSubmit: canSubmit,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isFinalScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFinalScreen
              ? 'Your documents are ready.'
              : '$_completedCount of 3 documents ready',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: AppFontWeights.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _completedCount / 3,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isFinalScreen
              ? 'Upload updates are complete. Review and submit when ready.'
              : 'Upload clear photos. JPG, PNG, WEBP accepted. Max 5 MB each.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context, {
    required ThemeData theme,
    required bool isFinalScreen,
    required bool canSubmit,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _completedCount == 0
                  ? 'Upload at least one document to submit.'
                  : '$_completedCount of 3 docs uploaded. You can submit with partial documents.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: isFinalScreen ? 'Back to Dashboard' : 'Submit for Review',
              onPressed: canSubmit
                  ? () {
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!();
                        return;
                      }
                      Navigator.pop(context);
                    }
                  : null,
              icon: Icons.send_rounded,
            ),
          ],
        ),
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
    this.imageUrl,
    this.imagePath,
  });

  final String docType;
  final KycDocumentUploadStatus status;
  final String? documentKey;
  final String? assetId;
  final String? imageUrl;
  final String? imagePath;
}
