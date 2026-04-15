import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../media/controller/media_upload_controller.dart';
import '../../../media/model/media_upload_models.dart';
import '../../../media/presentation/widgets/media_upload_tile.dart';
import '../../../media/presentation/widgets/refreshable_kyc_image_display.dart';
import '../../../media/service/kyc_image_url_provider.dart';
import '../../../media/service/media_upload_service.dart';
import '../../data/owner_auth_session_store.dart';
import '../../domain/owner_auth_models.dart';

// ============================================================================
// UploadDocumentsScreen — premium KYC upload flow
// ============================================================================

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({
    super.key,
    this.onSubmitted,
  });

  final VoidCallback? onSubmitted;

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen>
    with SingleTickerProviderStateMixin {
  final MediaUploadController _mediaController =
      MediaUploadController(service: MediaUploadService());
  final KycImageUrlProvider _imageUrlProvider = KycImageUrlProvider();
  final OwnerAuthSessionStore _sessionStore = OwnerAuthSessionStore();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _pageEntry;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final Map<String, MediaUploadResult> _uploadedDocs = {};
  final Map<String, UploadTileState> _tileStates = {};
  final Map<String, double> _tileProgress = {};
  final Map<String, String> _tileStatus = {};
  final Map<String, String> _localImagePaths = {};

  Map<String, String> _existingKycDocKeys = {};
  KycVerificationStatus _kycStatus = KycVerificationStatus.pending;
  String? _kycRejectionReason;
  Owner? _owner;
  String? _ownerId;
  bool _isSubmitting = false;
  List<KycDocumentItem> _previousUploadedDocs = [];

  static const _docs = [
    _KycDocInfo(
      docType: OwnerKycDocType.businessRegistration,
      title: 'Business Registration',
      subtitle: 'Company registration certificate',
      icon: Icons.business_outlined,
    ),
    _KycDocInfo(
      docType: OwnerKycDocType.citizenship,
      title: 'Citizenship Document',
      subtitle: "Owner's citizenship card or passport",
      icon: Icons.badge_outlined,
    ),
    _KycDocInfo(
      docType: OwnerKycDocType.businessPan,
      title: 'PAN Document',
      subtitle: 'Business PAN card',
      icon: Icons.receipt_long_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageEntry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim =
        CurvedAnimation(parent: _pageEntry, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageEntry, curve: Curves.easeOut));

    for (final doc in _docs) {
      _tileStates[doc.docType.value] = UploadTileState.idle;
      _tileProgress[doc.docType.value] = 0;
    }

    _loadOwnerData();
    _pageEntry.forward();
  }

  @override
  void dispose() {
    _pageEntry.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerData() async {
    final owner = await _sessionStore.getOwner();
    if (!mounted) return;
    setState(() {
      _owner = owner;
      _ownerId = owner?.id;
      _existingKycDocKeys = owner?.kycDocumentKeys ?? {};
      _kycStatus = owner?.kycStatus ?? KycVerificationStatus.pending;
      _kycRejectionReason = owner?.kycRejectionReason;
      for (final doc in _docs) {
        final existing = _existingKycDocKeys[doc.docType.value];
        if (existing != null && existing.isNotEmpty) {
          _tileStates[doc.docType.value] = UploadTileState.done;
        }
      }
    });
    _loadPreviouslyUploadedDocuments();
  }

  Future<void> _loadPreviouslyUploadedDocuments() async {
    if (!mounted) return;
    try {
      final response = await _mediaController.fetchAllKycDocuments();
      if (!mounted) return;
      
      debugPrint('📥 Fetched ${response.documents.length} KYC documents');
      for (final doc in response.documents) {
        debugPrint('   - ${doc.docType}: ${doc.downloadUrl.substring(0, 100)}...');
      }
      
      setState(() {
        _previousUploadedDocs = response.documents;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Failed to fetch previous documents: $e');
    }
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickAndUpload(OwnerKycDocType docType) async {
    final ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      _showSnack('Owner session not found. Please log in again.', isError: true);
      return;
    }

    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (selected == null || !mounted) return;

    HapticFeedback.mediumImpact();

    // Instantly show local preview
    setState(() {
      _localImagePaths[docType.value] = selected.path;
      _tileStates[docType.value] = UploadTileState.uploading;
      _tileProgress[docType.value] = 0;
      _tileStatus[docType.value] = 'Preparing…';
    });

    try {
      final bytes = await selected.readAsBytes();
      final contentType = _guessContentType(selected.name);

      final uploaded = await _mediaController.uploadKycDocument(
        docType: docType,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: true,  // ✅ Wait for image to be processed by backend
      );

      if (!mounted) return;

      final updatedOwner = _owner?.copyWith(
        kycDocumentKeys: {
          ..._existingKycDocKeys,
          docType.value: uploaded.key,
        },
        kycStatus: KycVerificationStatus.pending,
        kycRejectionReason: null,
      );
      if (updatedOwner != null) await _sessionStore.saveOwner(updatedOwner);
      await _sessionStore.saveKycDocKeyForOwner(
        ownerId: ownerId,
        docType: docType.value,
        storageKey: uploaded.key,
      );

      if (!mounted) return;

      setState(() {
        _uploadedDocs[docType.value] = uploaded;
        _tileStates[docType.value] = UploadTileState.done;
        _tileProgress[docType.value] = 1.0;
        _owner = updatedOwner;
        _existingKycDocKeys =
            updatedOwner?.kycDocumentKeys ?? _existingKycDocKeys;
        _kycStatus = KycVerificationStatus.pending;
        _kycRejectionReason = null;
      });

      HapticFeedback.lightImpact();
      _showSnack('Document uploaded successfully!');

      // ✨ IMPORTANT: Refresh previously uploaded documents to show the new upload
      await _loadPreviouslyUploadedDocuments();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tileStates[docType.value] = UploadTileState.error);
      _showSnack(
        _mediaController.errorMessage ?? 'Upload failed. Please try again.',
        isError: true,
      );
    }
  }

  int get _uploadedCount => _docs.where((doc) {
        final existing = _existingKycDocKeys[doc.docType.value];
        return _uploadedDocs.containsKey(doc.docType.value) ||
            (existing != null && existing.isNotEmpty);
      }).length;

  bool get _canSubmit => _uploadedCount > 0;

  List<Widget> _buildPreviousDocumentsList() {
    return List.generate(_previousUploadedDocs.length, (i) {
      final doc = _previousUploadedDocs[i];
      final docTypeEnum = doc.kycDocType;
      final docTypeName = _getDocTypeName(docTypeEnum);

      return Padding(
        padding:
            EdgeInsets.only(bottom: i < _previousUploadedDocs.length - 1 ? 12 : 0),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 450 + i * 50),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - v)),
              child: child,
            ),
          ),
          child: _PreviousDocumentCard(
            docType: docTypeName,
            downloadUrl: doc.downloadUrl,
            accentColor: const Color(0xFF00C896),
            imageUrlProvider: _imageUrlProvider,
            docTypeKey: doc.docType,
          ),
        ),
      );
    });
  }

  String _getDocTypeName(OwnerKycDocType? docType) {
    switch (docType) {
      case OwnerKycDocType.citizenship:
        return 'Citizenship Document';
      case OwnerKycDocType.businessRegistration:
        return 'Business Registration';
      case OwnerKycDocType.businessPan:
        return 'PAN Document';
      default:
        return 'Document';
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (widget.onSubmitted != null) {
      widget.onSubmitted!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF00C896);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                scrolledUnderElevation: 1,
                backgroundColor: colorScheme.surface,
                expandedHeight: 130,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KYC Verification',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$_uploadedCount of ${_docs.length} documents ready',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  background: _HeaderBackground(
                    uploadedCount: _uploadedCount,
                    total: _docs.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _KycBanner(
                      status: _kycStatus,
                      rejectionReason: _kycRejectionReason,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(),
                    const SizedBox(height: 22),
                    Text(
                      'Required Documents',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_docs.length, (i) {
                      final doc = _docs[i];
                      final k = doc.docType.value;
                      final existing = _existingKycDocKeys[k];
                      final isAlreadySubmitted =
                          existing != null &&
                              existing.isNotEmpty &&
                              !_uploadedDocs.containsKey(k);

                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: i < _docs.length - 1 ? 12 : 0),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 350 + i * 70),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - v)),
                              child: child,
                            ),
                          ),
                          child: MediaUploadTile(
                            label: doc.title,
                            subtitle: doc.subtitle,
                            icon: doc.icon,
                            localImagePath: _localImagePaths[k],
                            assetId: _uploadedDocs[k]?.assetId,
                            uploadState:
                                _tileStates[k] ?? UploadTileState.idle,
                            uploadProgress: _tileProgress[k] ?? 0,
                            statusMessage: _tileStatus[k],
                            isRequired: true,
                            isAlreadySubmitted: isAlreadySubmitted,
                            accentColor: accent,
                            onTap: _tileStates[k] == UploadTileState.uploading
                                ? null
                                : () => _pickAndUpload(doc.docType),
                            onRetry:
                                _tileStates[k] == UploadTileState.error
                                    ? () => _pickAndUpload(doc.docType)
                                    : null,
                          ),
                        ),
                      );
                    }),
                    if (_previousUploadedDocs.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Previously Uploaded',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildPreviousDocumentsList(),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        uploadedCount: _uploadedCount,
        total: _docs.length,
        canSubmit: _canSubmit,
        isSubmitting: _isSubmitting,
        onSubmit: _submit,
      ),
    );
  }
}

// ============================================================================
// Header background with progress
// ============================================================================

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.uploadedCount, required this.total});
  final int uploadedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF00C896);
    final progress = total > 0 ? uploadedCount / total : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.07),
            colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor:
                    colorScheme.outlineVariant.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _KycBanner
// ============================================================================

class _KycBanner extends StatelessWidget {
  const _KycBanner({required this.status, this.rejectionReason});
  final KycVerificationStatus status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (status == KycVerificationStatus.approved) {
      return _tile(
        context,
        icon: Icons.verified_rounded,
        title: 'KYC Approved',
        body: 'Your documents are verified. You can update anytime.',
        bg: const Color(0xFF00C896).withValues(alpha: 0.1),
        fg: const Color(0xFF00C896),
        border: const Color(0xFF00C896).withValues(alpha: 0.25),
      );
    }

    if (status == KycVerificationStatus.rejected) {
      return _tile(
        context,
        icon: Icons.cancel_rounded,
        title: 'Documents Rejected',
        body: rejectionReason?.isNotEmpty == true
            ? rejectionReason!
            : 'Please upload corrected documents and resubmit.',
        bg: colorScheme.errorContainer,
        fg: colorScheme.onErrorContainer,
        border: colorScheme.error.withValues(alpha: 0.25),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required Color bg,
    required Color fg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style:
                      TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _InfoRow
// ============================================================================

class _InfoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Upload clear photos. JPG, PNG, WEBP accepted. Max 5 MB each.',
              style: TextStyle(
                  color: cs.onPrimaryContainer, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _SubmitBar
// ============================================================================

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.uploadedCount,
    required this.total,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
  });
  final int uploadedCount;
  final int total;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFF00C896);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
            top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (uploadedCount < total)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '$uploadedCount of $total docs uploaded. You can submit with partial documents.',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilledButton(
                  onPressed:
                      canSubmit && !isSubmitting ? onSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        cs.outlineVariant.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Submit for Review',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _PreviousDocumentCard — Display previously uploaded KYC documents
// ============================================================================

class _PreviousDocumentCard extends StatefulWidget {
  const _PreviousDocumentCard({
    required this.docType,
    required this.downloadUrl,
    required this.accentColor,
    required this.imageUrlProvider,
    required this.docTypeKey,
  });

  final String docType;
  final String downloadUrl;
  final Color accentColor;
  final KycImageUrlProvider imageUrlProvider;
  final String docTypeKey;

  @override
  State<_PreviousDocumentCard> createState() => _PreviousDocumentCardState();
}

class _PreviousDocumentCardState extends State<_PreviousDocumentCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        color: widget.accentColor.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area with image
            _PreviousDocPreviewArea(
              downloadUrl: widget.downloadUrl,
              docType: widget.docTypeKey,
              accentColor: widget.accentColor,
              imageUrlProvider: widget.imageUrlProvider,
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.docType,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Previously uploaded',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.accentColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _PreviousDocPreviewArea — Show preview of previously uploaded image
// Now uses RefreshableKycImageDisplay for automatic URL expiry handling
// ============================================================================

class _PreviousDocPreviewArea extends StatefulWidget {
  const _PreviousDocPreviewArea({
    required this.downloadUrl,
    required this.docType,
    required this.accentColor,
    required this.imageUrlProvider,
  });

  final String downloadUrl;
  final String docType;
  final Color accentColor;
  final KycImageUrlProvider imageUrlProvider;

  @override
  State<_PreviousDocPreviewArea> createState() =>
      _PreviousDocPreviewAreaState();
}

class _PreviousDocPreviewAreaState extends State<_PreviousDocPreviewArea> {
  @override
  Widget build(BuildContext context) {
    return RefreshableKycImageDisplay(
      downloadUrl: widget.downloadUrl,
      docType: widget.docType,
      height: 140,
      width: double.infinity,
      onRefreshUrl: () =>
          widget.imageUrlProvider.refreshImageUrl(widget.docType),
    );
  }
}

class _KycDocInfo {
  const _KycDocInfo({
    required this.docType,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final OwnerKycDocType docType;
  final String title;
  final String subtitle;
  final IconData icon;
}
