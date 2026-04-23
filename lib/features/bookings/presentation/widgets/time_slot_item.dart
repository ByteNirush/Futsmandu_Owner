import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_shadows.dart';

enum SlotStatus {
  available,
  booked,
  blocked,
}

class TimeSlotItem extends StatelessWidget {
  const TimeSlotItem({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.teamName,
    this.bookingStatus,
    this.attendanceBadge,
    this.price,
    this.onTap,
  });

  final String startTime;
  final String endTime;
  final SlotStatus status;
  final String? teamName;
  final String? bookingStatus;
  final String? attendanceBadge;
  final String? price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Column
            SizedBox(
              width: 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    startTime,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    endTime,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            
            // Timeline Div
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: status == SlotStatus.available
                        ? colorScheme.surface
                        : status == SlotStatus.booked
                            ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: status == SlotStatus.available
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),

            // Content Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(colorScheme),
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                        border: Border.all(
                          color: _getBorderColor(colorScheme),
                          width: status == SlotStatus.available ? 1.5 : 1.0,
                        ),
                        boxShadow: status != SlotStatus.blocked ? AppShadows.card(colorScheme) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _getTitle(),
                                  style: textTheme.titleSmall?.copyWith(
                                    color: _getTextColor(colorScheme),
                                    fontWeight: AppFontWeights.semiBold,
                                  ),
                                ),
                              ),
                              if (price != null && status == SlotStatus.available)
                                Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                                  child: Text(
                                    price!,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: AppFontWeights.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _getSubtitle(),
                            style: textTheme.bodySmall?.copyWith(
                              color: _getSubtitleColor(colorScheme),
                            ),
                          ),
                          if (status == SlotStatus.booked &&
                              (bookingStatus != null || attendanceBadge != null)) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (bookingStatus != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bookingStatus!,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: AppFontWeights.bold,
                                      ),
                                    ),
                                ),
                                if (attendanceBadge != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _attendanceBadgeBackground(colorScheme),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      attendanceBadge!,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: _attendanceBadgeTextColor(colorScheme),
                                        fontWeight: AppFontWeights.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.booked:
        return teamName ?? 'Booked';
      case SlotStatus.blocked:
        return 'Blocked / Closed';
    }
  }

  String _getSubtitle() {
    switch (status) {
      case SlotStatus.available:
        return 'Tap to block or edit price';
      case SlotStatus.booked:
        return '$startTime - $endTime';
      case SlotStatus.blocked:
        return 'Unavailable for booking. Tap to reopen.';
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (status) {
      case SlotStatus.available:
        return colorScheme.surface;
      case SlotStatus.booked:
        return colorScheme.primaryContainer;
      case SlotStatus.blocked:
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    switch (status) {
      case SlotStatus.available:
        return colorScheme.primary.withValues(alpha: 0.5);
      case SlotStatus.booked:
        return colorScheme.primary.withValues(alpha: 0.3);
      case SlotStatus.blocked:
        return colorScheme.outlineVariant;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (status) {
      case SlotStatus.available:
        return colorScheme.primary;
      case SlotStatus.booked:
        return colorScheme.onPrimaryContainer;
      case SlotStatus.blocked:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _getSubtitleColor(ColorScheme colorScheme) {
    switch (status) {
      case SlotStatus.available:
        return colorScheme.onSurfaceVariant;
      case SlotStatus.booked:
        return colorScheme.onSurfaceVariant;
      case SlotStatus.blocked:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _attendanceBadgeBackground(ColorScheme colorScheme) {
    final badge = attendanceBadge?.toUpperCase() ?? '';
    if (badge.contains('NO-SHOW') || badge.contains('NO SHOW')) {
      return colorScheme.errorContainer;
    }
    return colorScheme.tertiaryContainer;
  }

  Color _attendanceBadgeTextColor(ColorScheme colorScheme) {
    final badge = attendanceBadge?.toUpperCase() ?? '';
    if (badge.contains('NO-SHOW') || badge.contains('NO SHOW')) {
      return colorScheme.onErrorContainer;
    }
    return colorScheme.onTertiaryContainer;
  }
}
