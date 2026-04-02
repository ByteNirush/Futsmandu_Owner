import 'package:flutter/material.dart';

import 'package:pinput/pinput.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../widgets/auth_header.dart';

class OtpVerificationScreen extends StatelessWidget {
  final VoidCallback? onVerify;
  
  const OtpVerificationScreen({super.key, this.onVerify});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Check if arguments were passed
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final nextRoute = args?['nextRoute'] as String?;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: bottomInset + AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 56), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const Center(child: AppLogo(size: 72.0)),
                    const SizedBox(height: AppSpacing.sm),
                    const AuthHeader(
                      title: 'Verify OTP',
                      subtitle: 'Enter the 6-digit code sent to your email',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Center(
                      child: Pinput(
                        length: 6,
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        submittedPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    AppButton(
                      label: 'Verify',
                      onPressed: () {
                        if (onVerify != null) {
                          onVerify!();
                        } else if (nextRoute != null) {
                          Navigator.pushReplacementNamed(context, nextRoute);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Center(
                      child: TextButton(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('OTP sent again!')),
                           );
                        },
                        child: const Text('Resend Code'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
