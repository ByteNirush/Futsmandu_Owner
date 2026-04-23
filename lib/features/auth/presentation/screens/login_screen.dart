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
          allowScroll: false,
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
                    showLabelAboveField: true,
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: OwnerAuthValidators.validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppInputField(
                    controller: _passwordController,
                    label: 'Password',
                    showLabelAboveField: true,
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: OwnerAuthValidators.validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: AppFontWeights.semiBold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Don't have an account?",
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
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text('Register'),
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
