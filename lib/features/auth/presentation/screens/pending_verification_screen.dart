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
                    'Pending admin verification',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    owner == null
                        ? 'Your owner account is waiting for admin approval before you can access the workspace.'
                        : '${owner.displayBusinessName} is waiting for admin approval before workspace access is granted.',
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
                            Text('Owner: ${owner.name}'),
                            const SizedBox(height: 6),
                            Text('Email: ${owner.email}'),
                            const SizedBox(height: 6),
                            Text('Phone: ${owner.phone}'),
                          ],
                        ),
                      ),
                    ),
                  if (owner != null) const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Upload documents',
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
