import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_extended_action_button.dart';
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

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('park')) return Icons.local_parking_rounded;
    if (lower.contains('wifi') || lower.contains('internet'))
      return Icons.wifi_rounded;
    if (lower.contains('food') || lower.contains('cafe')) return Icons.restaurant_rounded;
    if (lower.contains('seating') || lower.contains('lounge')) return Icons.chair_rounded;
    if (lower.contains('light') || lower.contains('flood')) return Icons.light_rounded;
    if (lower.contains('shoe') || lower.contains('equipment')) return Icons.sports_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Venues')),
      floatingActionButton: AppExtendedActionButton(
        heroTag: 'venues_add_fab',
        onPressed: _openCreateVenue,
        icon: Icons.add_rounded,
        label: 'Add Venue',
        tooltip: 'Add a new venue',
      ),
      body: ScreenStateView(
        state: _controller.state,
        emptyTitle: 'No venues yet',
        emptySubtitle: _controller.state == ScreenUiState.error
            ? (_controller.errorMessage ?? 'Unable to load venues right now.')
            : 'Add your first venue to start receiving bookings.',
        onRetry: _controller.loadVenues,
        content: RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: _controller.venues.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final venue = _controller.venues[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with image, name, address, and edit button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                    ),
                                    child: venue.imageUrl != null
                                        ? SafeNetworkImage(
                                            url: venue.imageUrl!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.sports_soccer_rounded,
                                              color: colorScheme.primary,
                                              size: 36,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                venue.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xxs,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_rounded,
                                                    size: 13,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.xxs,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      venue.displayAddress,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _openEditVenue(venue),
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                          ),
                                          splashRadius: 20,
                                          padding: const EdgeInsets.all(
                                              AppSpacing.xxs),
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Divider
                          const SizedBox(height: AppSpacing.sm),
                          Divider(
                            height: 1,
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          
                          // Verification status
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: venue.isVerified
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  venue.isVerified
                                      ? Icons.verified_rounded
                                      : Icons.info_rounded,
                                  size: 16,
                                  color: venue.isVerified
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  venue.isVerified
                                      ? 'Verified'
                                      : 'Pending Verification',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: venue.isVerified
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Status and courts row
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: venue.isActive
                                      ? colorScheme.secondary
                                          .withValues(alpha: 0.12)
                                      : colorScheme.outline
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      venue.isActive
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 14,
                                      color: venue.isActive
                                          ? colorScheme.secondary
                                          : colorScheme.outline,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      venue.isActive ? 'Active' : 'Inactive',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: venue.isActive
                                                ? colorScheme.secondary
                                                : colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sports_soccer_rounded,
                                      size: 14,
                                      color: colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      '${venue.courtsCount} court${venue.courtsCount == 1 ? '' : 's'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: colorScheme.tertiary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Amenities section
                          if (venue.amenities.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: venue.amenities
                                  .take(4)
                                  .map(
                                    (amenity) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colorScheme.outline
                                              .withValues(alpha: 0.1),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getAmenityIcon(amenity),
                                            size: 12,
                                            color: colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.xxs,
                                          ),
                                          Text(
                                            amenity,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
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
