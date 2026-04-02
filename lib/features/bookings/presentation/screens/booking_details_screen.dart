import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({
    super.key,
    this.state = ScreenUiState.content,
  });

  final ScreenUiState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Edit booking action
            },
            tooltip: 'Edit Booking',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Delete booking action
            },
            tooltip: 'Cancel Booking',
          ),
        ],
      ),
      body: ScreenStateView(
        state: state,
        emptyTitle: 'No booking details',
        emptySubtitle: 'Booking details will appear here.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.sports_soccer, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team Everest',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Confirmed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: 'March 29, 2026',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value: '6:00 PM - 7:00 PM',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: 'Court',
                    value: 'Court B',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.people_outline,
                    label: 'Players',
                    value: '10 players',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.payments_outlined,
                    label: 'Payment',
                    value: 'Paid - NPR 1,500',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: '98XXXXXXXX',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Message Team',
              icon: Icons.message_outlined,
              onPressed: () {
                // Message action
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
