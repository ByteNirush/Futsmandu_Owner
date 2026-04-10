import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../domain/owner_auth_validators.dart';
import '../controllers/owner_auth_controller.dart';
import '../widgets/auth_header.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.authController});

  final OwnerAuthController authController;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _flow = 'owner-auth';
  String? _nextRoute;
  String? _phone;
  String? _ownerId;

  bool get _isOwnerAuthFlow => _flow == 'owner-auth';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _flow = args['flow']?.toString() ?? _flow;
      _nextRoute = args['nextRoute']?.toString();
      _phone = args['phone']?.toString();
      _ownerId = args['ownerId']?.toString();
      final email = args['email']?.toString();
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isOwnerAuthFlow) {
      final ownerId = _ownerId?.trim();
      if (ownerId == null || ownerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing owner id for OTP verification.'),
          ),
        );
        return;
      }

      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) {
        return;
      }

      try {
        final result = await widget.authController.verifyOtp(
          ownerId: ownerId,
          otp: _otpController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
      return;
    }

    if (_nextRoute != null && _nextRoute!.isNotEmpty) {
      Navigator.pushReplacementNamed(context, _nextRoute!);
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _resend() async {
    if (!_isOwnerAuthFlow) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent again!')));
      return;
    }

    final ownerId = _ownerId?.trim();
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing owner id for OTP resend.')),
      );
      return;
    }

    try {
      final message = await widget.authController.resendOtp(ownerId: ownerId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    final subtitle = _isOwnerAuthFlow
        ? 'Enter the 6-digit code sent to ${_emailController.text.trim()}${_phone == null || _phone!.isEmpty ? '' : ' and ${_phone!}'}'
        : 'Enter the 6-digit code sent to your email';

    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
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
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const Center(child: AppLogo(size: 72.0)),
                        const SizedBox(height: AppSpacing.sm),
                        AuthHeader(
                          title: _isOwnerAuthFlow
                              ? 'Verify your account'
                              : 'Verify OTP',
                          subtitle: subtitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_isOwnerAuthFlow)
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Center(
                                  child: Pinput(
                                    controller: _otpController,
                                    length: 6,
                                    keyboardType: TextInputType.number,
                                    defaultPinTheme: PinTheme(
                                      width: 50,
                                      height: 60,
                                      textStyle: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                        border: Border.all(
                                          color: theme.colorScheme.outline,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    focusedPinTheme: PinTheme(
                                      width: 50,
                                      height: 60,
                                      textStyle: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        border: Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    submittedPinTheme: PinTheme(
                                      width: 50,
                                      height: 60,
                                      textStyle: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        border: Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Center(
                            child: Pinput(
                              controller: _otpController,
                              length: 6,
                              keyboardType: TextInputType.number,
                              defaultPinTheme: PinTheme(
                                width: 50,
                                height: 60,
                                textStyle: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              focusedPinTheme: PinTheme(
                                width: 50,
                                height: 60,
                                textStyle: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              submittedPinTheme: PinTheme(
                                width: 50,
                                height: 60,
                                textStyle: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Verify',
                          isLoading: widget.authController.isBusy,
                          onPressed: widget.authController.isBusy
                              ? null
                              : _verify,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextButton(
                            onPressed: widget.authController.isBusy
                                ? null
                                : _resend,
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
      },
    );
  }
}
