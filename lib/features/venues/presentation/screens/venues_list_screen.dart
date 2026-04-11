import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/safe_network_image.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../domain/models/venue_models.dart';
import '../controllers/venues_list_controller.dart';
import 'create_venue_screen.dart';
import 'venue_details_screen.dart';

class VenuesListScreen extends StatefulWidget {
  const VenuesListScreen({super.key});

  @override
  State<VenuesListScreen> createState() => _VenuesListScreenState();
}

class _VenuesListScreenState extends State<VenuesListScreen> {
  final VenuesListController _controller = VenuesListController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadVenues();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openCreateVenue() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateVenueScreen()));

    if (created == true && mounted) {
      await _controller.reloadAfterMutation();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue created successfully.')),
      );
    }
  }

  Future<void> _openEditVenue(Venue venue) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateVenueScreen(isEditMode: true, initialVenue: venue),
      ),
    );

    if (updated == true && mounted) {
      await _controller.reloadAfterMutation();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Venues')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'venues_add_fab',
        onPressed: _openCreateVenue,
        icon: const Icon(Icons.add),
        label: const Text('Add Venue'),
      ),
      body: ScreenStateView(
        state: _controller.state,
        emptyTitle: 'No venues yet',
        emptySubtitle: _controller.state == ScreenUiState.error
            ? (_controller.errorMessage ??
                  'Unable to load venues right now.')
            : 'Add your first venue to start receiving bookings.',
        onRetry: _controller.loadVenues,
        content: RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xs),
            itemCount: _controller.venues.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              final venue = _controller.venues[index];
              return AppCard(
                padding: EdgeInsets.zero,
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => VenueDetailsScreen(venue: venue),
                    ),
                  );
                  if (changed == true && mounted) {
                    await _controller.reloadAfterMutation();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                              ),
                              child: venue.imageUrl != null
                                  ? SafeNetworkImage(
                                      url: venue.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.sports_soccer,
                                        color: colorScheme.onPrimary,
                                        size: 28,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venue.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  venue.displayAddress,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    Chip(
                                      label: Text(
                                        venue.isVerified
                                            ? 'Verified'
                                            : 'Pending Verification',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Chip(
                                      label: Text(
                                        venue.isActive ? 'Active' : 'Inactive',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Chip(
                                      label: Text(
                                        '${venue.courtsCount} courts',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openEditVenue(venue),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      if (venue.amenities.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: venue.amenities
                              .take(4)
                              .map(
                                (amenity) => Chip(
                                  label: Text(amenity),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
