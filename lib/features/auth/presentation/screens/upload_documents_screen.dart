import 'package:flutter/material.dart';

import '../../../../core/network/owner_api_client.dart';
import '../../data/owner_auth_api.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';
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
  final OwnerAuthApi _authApi = OwnerAuthApi();
  final Map<String, UploadDocUrl> _uploadedDocs = <String, UploadDocUrl>{};
  final Set<String> _pendingDocTypes = <String>{};

  Future<void> _generateUploadUrl(String docType, String title) async {
    setState(() => _pendingDocTypes.add(docType));
    try {
      final upload = await _authApi.uploadDocs(docType: docType);
      if (!mounted) {
        return;
      }
      setState(() => _uploadedDocs[docType] = upload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title upload URL generated.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate upload URL.')),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingDocTypes.remove(docType));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const docs = [
      ('Business Registration', 'business_reg'),
      ('Citizenship Document', 'citizenship'),
      ('PAN Document', 'pan'),
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
              title: 'Business Verification',
              subtitle: 'Upload documents for account activation',
            ),
            const SizedBox(height: AppSpacing.md),
            ...docs.map((doc) {
              final title = doc.$1;
              final docType = doc.$2;
              final upload = _uploadedDocs[docType];
              final isLoading = _pendingDocTypes.contains(docType);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.upload_file_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title),
                            if (upload != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Key: ${upload.key}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppButton(
                        label: upload == null ? 'Generate URL' : 'Regenerate',
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => _generateUploadUrl(docType, title),
                        variant: AppButtonVariant.outlined,
                        expand: false,
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
