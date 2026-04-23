import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../domain/owner_auth_validators.dart';
import '../controllers/owner_auth_controller.dart';
import '../../../../shared/widgets/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authController});

  final OwnerAuthController authController;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = await widget.authController.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        businessName: _businessNameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.pushReplacementNamed(
        context,
        '/otp-verification',
        arguments: {
          'flow': 'owner-auth',
          'ownerId': result.owner.id,
          'email': result.owner.email,
          'phone': result.owner.phone,
        },
      );
    } on Exception catch (error) {
      if (!mounted) return;
      final message =
          widget.authController.errorMessage ??
          error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return AuthScaffold(
          role: AppRole.owner,
          child: AuthCard(
            role: AppRole.owner,
            title: 'Create Owner Account',
            subtitle: 'Register your futsal business',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInputField(
                    controller: _nameController,
                    label: 'Owner name',
                    showLabelAboveField: true,
                    hint: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    validator: OwnerAuthValidators.validateName,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppInputField(
                    controller: _businessNameController,
                    label: 'Business name',
                    showLabelAboveField: true,
                    hint: 'Enter your business name',
                    prefixIcon: Icons.storefront_outlined,
                    validator: OwnerAuthValidators.validateBusinessName,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppInputField(
                    controller: _emailController,
                    label: 'Email',
                    showLabelAboveField: true,
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: OwnerAuthValidators.validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppInputField(
                    controller: _phoneController,
                    label: 'Phone',
                    showLabelAboveField: true,
                    hint: '98XXXXXXXX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: OwnerAuthValidators.validateNepalPhone,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppInputField(
                    controller: _passwordController,
                    label: 'Password',
                    showLabelAboveField: true,
                    hint: 'Create password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: OwnerAuthValidators.validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppInputField(
                    controller: _confirmPasswordController,
                    label: 'Confirm password',
                    showLabelAboveField: true,
                    hint: 'Confirm password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Create account',
                    isLoading: widget.authController.isBusy,
                    onPressed: widget.authController.isBusy ? null : _register,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
