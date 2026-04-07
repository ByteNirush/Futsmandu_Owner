import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/components/buttons/primary_button.dart';
import 'package:futsmandu_design_system/components/buttons/secondary_button.dart';

import '../../core/design_system/app_spacing.dart';

enum AppButtonVariant { filled, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.variant = AppButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.text) {
      final textChild = isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                const SizedBox(width: AppSpacing.xs),
                Text(label),
              ],
            );

      final textButton = SizedBox(
        height: AppSpacing.buttonHeight,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          child: textChild,
        ),
      );
      if (expand) {
        return SizedBox(width: double.infinity, child: textButton);
      }
      return IntrinsicWidth(child: textButton);
    }

    final iconWidget = icon == null ? null : Icon(icon, size: 18);
    if (variant == AppButtonVariant.outlined) {
      return SecondaryButton(
        label: label,
        onPressed: onPressed,
        icon: iconWidget,
        fullWidth: expand,
      );
    }

    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: iconWidget,
      isLoading: isLoading,
      fullWidth: expand,
    );
  }
}
