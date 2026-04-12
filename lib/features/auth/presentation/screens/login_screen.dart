import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../domain/owner_auth_validators.dart';
import '../controllers/owner_auth_controller.dart';
import '../../../../shared/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authController});

  final OwnerAuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await widget.authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
            title: 'Welcome Back',
            subtitle: 'Sign in to manage your futsal venue',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInputField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: OwnerAuthValidators.validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppInputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: OwnerAuthValidators.validatePassword,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: 'Sign In',
                    isLoading: widget.authController.isBusy,
                    onPressed: widget.authController.isBusy ? null : _signIn,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: AppFontWeights.semiBold,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Create Account',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pushNamed(context, '/register'),
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
