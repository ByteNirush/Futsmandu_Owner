import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

class UpcomingBookingItem extends StatelessWidget {
  const UpcomingBookingItem({
    super.key,
    required this.teamName,
    required this.courtName,
    required this.timeSlot,
    required this.status,
  });

  final String teamName;
  final String courtName;
  final String timeSlot;
  final String status;

  Color _statusColor(ColorScheme colorScheme, String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return colorScheme.primary;
      case 'cancelled':
      case 'canceled':
        return colorScheme.error;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return colorScheme.secondary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colorScheme, status);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teamName, style: Theme.of(context).textTheme.titleSmall),
                Text('$courtName • $timeSlot'),
              ],
            ),
          ),
          Chip(
            backgroundColor: statusColor.withValues(alpha: 0.18),
            side: BorderSide(color: statusColor.withValues(alpha: 0.45)),
            label: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
