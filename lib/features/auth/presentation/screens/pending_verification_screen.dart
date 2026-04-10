import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../controllers/owner_auth_controller.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key, required this.authController});

  final OwnerAuthController authController;

  @override
  Widget build(BuildContext context) {
    final owner = authController.owner;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(size: 84),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Complete KYC Verification',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your account is verified, but we need to complete Know Your Customer (KYC) verification to activate all features. This is a one-time process.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (owner != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Details',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Business: ${owner.displayBusinessName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Email: ${owner.email}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Phone: ${owner.phone}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (owner != null) const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outlined,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Required Documents:',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '• Business Registration Certificate\n• Personal Citizenship Document\n• Business PAN/Tax ID',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Upload KYC Documents',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/upload-documents');
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Logout',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      await authController.logout();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
