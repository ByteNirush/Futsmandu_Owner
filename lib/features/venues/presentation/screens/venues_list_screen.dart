import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_shadows.dart';
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
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card(colorScheme),
                ),
                child: Material(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  surfaceTintColor: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Premium Image banner
                        Stack(
                          children: [
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primaryContainer.withValues(alpha: 0.6),
                                    colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: venue.imageUrl != null
                                  ? SafeNetworkImage(
                                      url: venue.imageUrl!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.sports_soccer_rounded,
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        size: 64,
                                      ),
                                    ),
                            ),
                            // Subtle overlay gradient at the top right to make the edit button pop
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.4],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: IconButton(
                                    onPressed: () => _openEditVenue(venue),
                                    icon: const Icon(Icons.edit_rounded),
                                    color: colorScheme.onSurface,
                                    splashColor: colorScheme.primary.withValues(alpha: 0.1),
                                    highlightColor: colorScheme.primary.withValues(alpha: 0.05),
                                    splashRadius: 24,
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                    constraints: const BoxConstraints(),
                                    iconSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Content area
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: AppFontWeights.bold,
                                      letterSpacing: -0.5,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Expanded(
                                    child: Text(
                                      venue.displayAddress,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.2,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: AppSpacing.md),
                              
                              // Badges section wrapped for better responsiveness
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  // Verification status
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: venue.isVerified
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : AppColors.warning.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
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
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: venue.isVerified
                                                    ? AppColors.success
                                                    : AppColors.warning,
                                                letterSpacing: 0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Active status
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: venue.isActive
                                          ? colorScheme.secondary.withValues(alpha: 0.12)
                                          : colorScheme.outline.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          venue.isActive
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          size: 16,
                                          color: venue.isActive
                                              ? colorScheme.secondary
                                              : colorScheme.outline,
                                        ),
                                        const SizedBox(width: AppSpacing.xxs),
                                        Text(
                                          venue.isActive ? 'Active' : 'Inactive',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: venue.isActive
                                                    ? colorScheme.secondary
                                                    : colorScheme.outline,
                                                letterSpacing: 0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Courts count
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sports_soccer_rounded,
                                          size: 16,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: AppSpacing.xxs),
                                        Text(
                                          '${venue.courtsCount} court${venue.courtsCount == 1 ? '' : 's'}',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: colorScheme.tertiary,
                                                letterSpacing: 0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Amenities section
                              if (venue.amenities.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: venue.amenities
                                      .take(4)
                                      .map(
                                        (amenity) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(20), // Pill shape for amenities
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                amenity,
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
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
                      ],
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
