import 'package:flutter/material.dart';

import '../../../../core/network/owner_api_client.dart';
import '../../data/owner_auth_api.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final OwnerAuthApi _authApi = OwnerAuthApi();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;

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

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authApi.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        businessName: _businessNameController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please sign in.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create account. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
                    AppInputField(
                      controller: _nameController,
                      label: 'Owner name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppInputField(
                      controller: _businessNameController,
                      label: 'Business name',
                      hint: 'Enter your business name',
                      prefixIcon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppInputField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppInputField(
                      controller: _phoneController,
                      label: 'Phone',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Create password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppInputField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hint: 'Confirm password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                    ),

                    // ── Primary CTA ─────────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Create account',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _register,
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
