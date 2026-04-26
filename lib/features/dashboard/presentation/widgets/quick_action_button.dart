import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2, horizontal: AppSpacing.xxs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                height: 1.1,
                fontSize: 10,
                fontWeight: AppFontWeights.medium,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

  }
}

