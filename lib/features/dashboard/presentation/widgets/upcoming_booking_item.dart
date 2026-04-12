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
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(colorScheme, status);

    // Zero-padding card so we can place the accent strip flush with the left edge.
    // Card's clipBehavior: antiAlias (set in theme) automatically clips the
    // strip's top-left and bottom-left corners to match the card's border radius.
    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left status accent strip
            Container(
              width: 4,
              color: statusColor,
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs2,
                  vertical: AppSpacing.xs2,
                ),
                child: Row(
                  children: [
                    // Leading icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_available_outlined,
                        size: 18,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Team & court info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '$courtName · $timeSlot',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    // Lightweight status badge (replaces the heavier Chip)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
