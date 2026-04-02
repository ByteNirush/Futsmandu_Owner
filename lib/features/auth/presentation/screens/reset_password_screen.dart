import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../widgets/auth_header.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                      title: 'Set New Password',
                      subtitle: 'Enter your new password below',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    const AppInputField(
                      label: 'New Password',
                      hint: 'Create new password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppInputField(
                      label: 'Confirm Password',
                      hint: 'Confirm new password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    AppButton(
                      label: 'Save Password',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset successfully!')),
                        );
                        // Navigate back to login
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/login', 
                          (route) => false,
                        );
                      },
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
