import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                      title: 'Create Owner Account',
                      subtitle: 'Register your futsal business',
                    ),

                    // ── Input fields ────────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    const AppInputField(
                      label: 'Business name',
                      hint: 'Enter your business name',
                      prefixIcon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppInputField(
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppInputField(
                      label: 'Phone',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppInputField(
                      label: 'Password',
                      hint: 'Create password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppInputField(
                      label: 'Confirm password',
                      hint: 'Confirm password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                    ),

                    // ── Primary CTA ─────────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Continue to OTP verification',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/otp-verification',
                        arguments: {'nextRoute': '/shell'},
                      ),
                    ),

                    // ── Footer link ─────────────────────────────────────────
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Already have an account? Login'),
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
