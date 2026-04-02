import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80.0,
  });

  static const String _darkModeLogoPath = 'assets/White_logo.png';
  static const String _lightModeLogoPath = 'assets/black_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = size * 0.25;
    final isDarkMode = theme.brightness == Brightness.dark;
    final logoPath = isDarkMode ? _darkModeLogoPath : _lightModeLogoPath;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Image.asset(
              logoPath,
              key: ValueKey<String>(logoPath),
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Futsmandu',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
