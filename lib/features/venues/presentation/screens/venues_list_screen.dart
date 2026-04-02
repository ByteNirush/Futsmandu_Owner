import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import 'create_venue_screen.dart';
import 'venue_details_screen.dart';

class VenuesListScreen extends StatelessWidget {
  const VenuesListScreen({
    super.key,
    this.state = ScreenUiState.content,
  });

  final ScreenUiState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search venues
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateVenueScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Venue'),
      ),
      body: ScreenStateView(
        state: state,
        emptyTitle: 'No venues yet',
        emptySubtitle: 'Add your first venue to start receiving bookings.',
        content: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.sm),
          itemCount: 2,
          separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final venue = _sampleVenues[index];
            return AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VenueDetailsScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue['name']!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                // Increase contrast in dark mode.
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  venue['address']!,
                                  // `bodySmall` is intentionally lighter in the design
                                  // system; Venues needs stronger contrast in dark mode.
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Edit',
                      expand: false,
                      icon: Icons.edit_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateVenueScreen(isEditMode: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const List<Map<String, String>> _sampleVenues = [
    {'name': 'Futsmandu Arena', 'address': 'Baneshwor, Kathmandu'},
    {'name': 'Futsal Hub', 'address': 'Lazimpat, Kathmandu'},
  ];
}
