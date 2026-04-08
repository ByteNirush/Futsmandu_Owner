import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/controllers/owner_auth_controller.dart';
import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/upload_documents_screen.dart';

void main() {
  runApp(const FutsmanduApp());
}

class FutsmanduApp extends StatefulWidget {
  const FutsmanduApp({super.key});

  @override
  State<FutsmanduApp> createState() => _FutsmanduAppState();
}

class _FutsmanduAppState extends State<FutsmanduApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final OwnerAuthController _authController = OwnerAuthController();

  @override
  void dispose() {
    _authController.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'Futsmandu Owner App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeProvider.themeMode,
          home: AuthGateScreen(
            authController: _authController,
            themeProvider: _themeProvider,
          ),
          routes: {
            '/login': (_) => LoginScreen(authController: _authController),
            '/register': (_) => RegisterScreen(authController: _authController),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/otp-verification': (_) => const OtpVerificationScreen(),
            '/reset-password': (_) => const ResetPasswordScreen(),
            '/upload-documents': (_) => const UploadDocumentsScreen(),
            '/shell': (_) => OwnerShellScreen(
              authController: _authController,
              themeProvider: _themeProvider,
            ),
          },
        );
      },
    );
  }
}
