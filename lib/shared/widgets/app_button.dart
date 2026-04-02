import 'package:flutter/material.dart';

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
    final buttonChild = isLoading
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

    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
    };

    final content = SizedBox(height: AppSpacing.buttonHeight, child: button);
    if (expand) {
      return SizedBox(width: double.infinity, child: content);
    }
    return IntrinsicWidth(child: content);
  }
}
