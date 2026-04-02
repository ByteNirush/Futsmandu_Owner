import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../widgets/auth_header.dart';

class UploadDocumentsScreen extends StatelessWidget {
  const UploadDocumentsScreen({super.key, this.state = ScreenUiState.content});

  final ScreenUiState state;

  @override
  Widget build(BuildContext context) {
    const docs = [
      'Business Registration',
      'Citizenship Document',
      'PAN Document',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: ScreenStateView(
        state: state,
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
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(doc)),
                      AppButton(
                        label: 'Choose File',
                        onPressed: () {},
                        variant: AppButtonVariant.outlined,
                        expand: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Submit for review',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false),
            ),
          ],
        ),
      ),
    );
  }
}
