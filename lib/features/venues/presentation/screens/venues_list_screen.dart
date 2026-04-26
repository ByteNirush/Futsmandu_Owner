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
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('My Venues'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.xl,
            ),
            itemCount: _controller.venues.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final venue = _controller.venues[index];
              return _VenueCard(
                venue: venue,
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
                onEdit: () => _openEditVenue(venue),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Venue Card (Clean, Modern Design - Matching Player App)
// ─────────────────────────────────────────────────────────────────────────────

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.onTap,
    required this.onEdit,
  });

  final Venue venue;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
        boxShadow: AppShadows.card(colorScheme),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VenueCardImage(
                imageUrl: venue.imageUrl ?? '',
                isVerified: venue.isVerified,
                onEdit: onEdit,
              ),
              _VenueCardBody(
                venue: venue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image Section ───────────────────────────────────────────────────────────

class _VenueCardImage extends StatelessWidget {
  const _VenueCardImage({
    required this.imageUrl,
    required this.isVerified,
    required this.onEdit,
  });

  final String imageUrl;
  final bool isVerified;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 172,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover photo
          imageUrl.isNotEmpty
              ? SafeNetworkImage(
                  url: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              : ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.sports_soccer_rounded,
                      size: 48,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),

          // Top gradient for badge contrast
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  colorScheme.scrim.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Edit button — top right
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _BadgePill(
              color: colorScheme.surface.withValues(alpha: 0.9),
              onTap: onEdit,
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Verified pill — top left
          if (isVerified)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: _BadgePill(
                color: AppColors.success,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: AppFontWeights.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.color,
    required this.child,
    this.onTap,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: child,
      ),
    );
  }
}

// ── Body Section ─────────────────────────────────────────────────────────────

class _VenueCardBody extends StatelessWidget {
  const _VenueCardBody({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            venue.name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeights.bold,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.xxs + 1),

          // Address
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  venue.displayAddress,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Status badges row
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xxs + 2,
            runSpacing: AppSpacing.xxs + 2,
            children: [
              // Active status chip
              _StatusChip(
                label: venue.isActive ? 'Active' : 'Inactive',
                isActive: venue.isActive,
              ),
              // Courts count
              Text(
                '${venue.courtsCount} court${venue.courtsCount == 1 ? '' : 's'}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
            ],
          ),

          // Amenities
          if (venue.amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xxs + 2,
              runSpacing: AppSpacing.xxs + 2,
              children: venue.amenities.take(3).map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  ),
                  child: Text(
                    amenity,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final color = isActive ? AppColors.success : colorScheme.outline;

    return Text(
      label,
      style: textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: AppFontWeights.semiBold,
      ),
    );
  }
}
