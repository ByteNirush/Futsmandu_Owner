import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../widgets/auth_header.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo ───────────────────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    const Center(child: AppLogo(size: 72.0)),

                    // ── Section header ──────────────────────────────────────
                    const SizedBox(height: AppSpacing.sm),
                    const AuthHeader(
                      title: 'Reset Password',
                      subtitle: 'Enter your email to receive a password reset link',
                    ),

                    // ── Input fields ────────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    const AppInputField(
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // ── Primary CTA ─────────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Send Reset Link',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP sent to your email!')),
                        );
                        Navigator.pushNamed(
                          context,
                          '/otp-verification',
                          arguments: {'nextRoute': '/reset-password'},
                        );
                      },
                    ),

                    // ── Footer link ─────────────────────────────────────────
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Login'),
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
