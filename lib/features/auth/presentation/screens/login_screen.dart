import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart'
    hide AppSpacing;

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../domain/owner_auth_validators.dart';
import '../controllers/owner_auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authController});

  final OwnerAuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    try {
      await widget.authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
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
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
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
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.xl),
                              const Center(child: AppLogo(size: 76)),
                              const SizedBox(height: AppSpacing.lg),
                              AppContainer(
                                useShadow: true,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                backgroundColor: theme.colorScheme.surface,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CustomText(
                                      'Welcome Back',
                                      variant: CustomTextVariant.subHeading,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    CustomText(
                                      'Sign in to manage your futsal venue',
                                      variant: CustomTextVariant.body,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    AppInputField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator:
                                          OwnerAuthValidators.validateEmail,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppInputField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      isPassword: true,
                                      textInputAction: TextInputAction.done,
                                      validator:
                                          OwnerAuthValidators.validatePassword,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          '/forgot-password',
                                        ),
                                        child: const Text('Forgot Password?'),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppButton(
                                      label: 'Sign In',
                                      onPressed: widget.authController.isBusy
                                          ? null
                                          : _signIn,
                                      isLoading: widget.authController.isBusy,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        const Expanded(child: Divider()),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                          ),
                                          child: CustomText(
                                            'OR',
                                            variant: CustomTextVariant.caption,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AppButton(
                                      label: 'Create Account',
                                      variant: AppButtonVariant.outlined,
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        '/register',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
