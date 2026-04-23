import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../../../shared/widgets/app_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 64) return 'Password must be 64 characters or less';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Backend call goes here — wired up by the consuming screen's controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successfully!')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      role: AppRole.owner,
      showAppBar: true,
      child: AuthCard(
        role: AppRole.owner,
        title: 'Set New Password',
        subtitle: 'Enter your new password below',
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInputField(
                controller: _newPasswordController,
                label: 'New Password',
                showLabelAboveField: true,
                hint: 'Create new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppInputField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                showLabelAboveField: true,
                hint: 'Confirm new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Save Password',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _savePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
