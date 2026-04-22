import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import 'upload_documents_screen.dart';

class KycIntroScreen extends StatelessWidget {
  const KycIntroScreen({super.key});

  Future<void> _openUploadFlow(BuildContext context) async {
    final didSubmit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UploadDocumentsScreen(
          onSubmitted: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (didSubmit == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 420,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Back',
                            style: IconButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const _KycHeroIllustration(),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Complete Your eKYC',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: AppFontWeights.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          'To keep your account secure and fully functional, we need to verify your identity.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Steps to complete eKYC',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: AppFontWeights.semiBold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _StepText(
                              text:
                                  'Upload a government-issued ID (Aadhaar, PAN, Passport, etc.)',
                            ),
                            _StepText(text: 'Upload a clear selfie'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: AppSpacing.buttonHeight,
                        child: FilledButton(
                          onPressed: () => _openUploadFlow(context),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Verify & Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        '- $text',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

class _KycHeroIllustration extends StatelessWidget {
  const _KycHeroIllustration();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Positioned(
            left: 42,
            top: 54,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.surfaceContainer,
              child: Icon(
                Icons.shield_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            right: 42,
            top: 90,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.surfaceContainer,
              child: Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 138,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.primary, width: 3),
            ),
            child: Column(
              children: [
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md - 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
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
