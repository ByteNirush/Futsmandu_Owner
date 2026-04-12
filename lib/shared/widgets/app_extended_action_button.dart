import 'package:flutter/material.dart';

import '../../core/design_system/app_radius.dart';

class AppExtendedActionButton extends StatelessWidget {
  const AppExtendedActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.heroTag,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Object? heroTag;
  final String? tooltip;

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
        backgroundColor: enabled
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        foregroundColor: enabled
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
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
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
          ),
        ),
      ),
    );
  }
}
