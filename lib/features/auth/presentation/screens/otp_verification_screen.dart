
import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';


import '../controllers/owner_auth_controller.dart';


class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.authController});

  final OwnerAuthController authController;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  String _flow = 'owner-auth';
  String? _nextRoute;
  String? _ownerId;

  bool get _isOwnerAuthFlow => _flow == 'owner-auth';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _flow = args['flow']?.toString() ?? _flow;
      _nextRoute = args['nextRoute']?.toString();
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

      if (!_formKey.currentState!.validate()) return;

      try {
        final result = await widget.authController.verifyOtp(
          ownerId: ownerId,
          otp: _otpController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/', (route) => false);
      } on Exception catch (error) {
        if (!mounted) return;
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
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = colorScheme.primary;
    
    // Fallback format if email exists
    final emailDisplay = _emailController.text.trim();
    final hasEmail = emailDisplay.isNotEmpty;
    
    final destination = hasEmail ? emailDisplay : 'your email';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0, // No horizontal dividing line when scrolled
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.authController,
          builder: (context, _) {
            final isBusy = widget.authController.isBusy;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Branding: Logo at the top
                  const AppLogo(size: 56),
                  const SizedBox(height: 32),
                  
                  // Typography: Heading
                  Text(
                    _isOwnerAuthFlow ? 'Verify your account' : 'Verify OTP',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withValues(alpha: 0.9), // Dark slate gray equivalent
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Typography: Instruction Text
                  Text(
                    'Enter the 6-digit code sent to',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8), // Softer, legible gray
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Read-only confirmed data for email/phone
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      destination,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),
                  
                  // OTP Inputs Area
                  Form(
                    key: _formKey,
                    child: Center(
                      child: OtpPinInput(
                        controller: _otpController,
                        enabled: !isBusy,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 56),
                  
                  // Call to Action: Large, pill-shaped primary button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Pill-shaped
                        ),
                        elevation: 0,
                      ),
                      onPressed: isBusy ? null : _verify,
                      child: isBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Secondary Action: Clean text-only link
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: isBusy ? null : _resend,
                    child: const Text('Resend Code'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
