import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

enum AppButtonVariant {
  primary,
  filled,
  outlined,
}

/// Owner-app button wrapper that delegates to the design system buttons.
///
/// Keeps a stable local API (`label`, `onPressed`, `isLoading`, `variant`)
/// so every existing call-site compiles unchanged while the rendered widget
/// comes from the shared design system.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final iconWidget = icon == null ? null : Icon(icon, size: 18);

    if (variant == AppButtonVariant.outlined) {
      return SecondaryButton(
        label: label,
        onPressed: isDisabled ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : iconWidget,
        fullWidth: expand,
      );
    }

    // `filled` is a backward-compatible alias for the current `primary` style.
    return PrimaryButton(
      label: label,
      onPressed: isDisabled ? null : onPressed,
      icon: iconWidget,
      isLoading: isLoading,
      fullWidth: expand,
    );
  }
}
