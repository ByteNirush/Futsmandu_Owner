import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../core/design_system/app_radius.dart';

class AppExtendedActionButton extends StatelessWidget {
  const AppExtendedActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.heroTag,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Object? heroTag;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip ?? label,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: backgroundColor ??
            (enabled
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest),
        foregroundColor: foregroundColor ??
            (enabled
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant),
        elevation: enabled ? 8 : 0,
        focusElevation: enabled ? 10 : 0,
        hoverElevation: enabled ? 12 : 0,
        highlightElevation: enabled ? 14 : 0,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: AppFontWeights.bold,
            letterSpacing: 0.15,
          ),
        ),
      ),
    );
  }
}
