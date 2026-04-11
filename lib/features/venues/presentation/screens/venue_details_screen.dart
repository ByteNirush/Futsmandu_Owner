import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/safe_network_image.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../courts/presentation/screens/create_court_screen.dart';
import '../../domain/models/court_models.dart';
import '../../domain/models/venue_models.dart';
import '../controllers/venue_courts_controller.dart';
import 'create_venue_screen.dart';

class VenueDetailsScreen extends StatefulWidget {
  const VenueDetailsScreen({super.key, required this.venue});

  final Venue venue;

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  final VenueCourtsController _courtsController = VenueCourtsController();

  @override
  void initState() {
    super.initState();
    _courtsController.loadCourts(widget.venue.id);
  }

  @override
  void dispose() {
    _courtsController.dispose();
    super.dispose();
  }

  Future<void> _openCreateCourt() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCourtScreen(venueId: widget.venue.id),
      ),
    );
    if (changed == true && mounted) {
      await _courtsController.loadCourts(widget.venue.id);
    }
  }

  Future<void> _openEditVenue() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateVenueScreen(isEditMode: true, initialVenue: widget.venue),
      ),
    );
    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openEditCourt(Court court) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateCourtScreen(venueId: widget.venue.id, initialCourt: court),
      ),
    );
    if (changed == true && mounted) {
      await _courtsController.loadCourts(widget.venue.id);
    }
  }

  Future<void> _deleteCourt(Court court) async {
    if (!_courtsController.canDeleteCourt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only OWNER_ADMIN can delete courts.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete court?'),
        content: Text(
          'This will soft delete ${court.name}. Existing bookings remain unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await _courtsController.deleteCourt(
        venueId: widget.venue.id,
        courtId: court.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${court.name} deleted.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _courtsController.errorMessage ?? 'Failed to delete court.',
          ),
        ),
      );
    }
  }

  Widget _imagePlaceholder(
    BuildContext context,
    ColorScheme colorScheme, {
    required String label,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _courtsController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.venue.name),
            actions: [
              IconButton(
                onPressed: _openEditVenue,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _courtsController.loadCourts(widget.venue.id),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                if (!widget.venue.isVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Pending Verification: this venue is awaiting admin approval.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: widget.venue.imageUrl != null
                            ? SafeNetworkImage(
                                url: widget.venue.imageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              )
                            : _imagePlaceholder(
                                context,
                                colorScheme,
                                label: 'No venue image yet',
                              ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.venue.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.venue.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              widget.venue.displayAddress,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Lat ${widget.venue.latitude}, Lng ${widget.venue.longitude}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Chip(
                            label: Text(
                              widget.venue.isVerified
                                  ? 'Verified'
                                  : 'Pending Verification',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              widget.venue.isActive ? 'Active' : 'Inactive',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      if (widget.venue.amenities.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: widget.venue.amenities
                              .map((amenity) => Chip(label: Text(amenity)))
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Court Management Dashboard',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Chip(
                              label: Text(
                                '${_courtsController.courts.length} total',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Court Management Dashboard',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Chip(
                            label: Text(
                              '${_courtsController.courts.length} total',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Courts',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppButton(
                            label: 'Add Court',
                            expand: false,
                            icon: Icons.add,
                            variant: AppButtonVariant.filled,
                            onPressed: _openCreateCourt,
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Courts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppButton(
                          label: 'Add Court',
                          expand: false,
                          icon: Icons.add,
                          variant: AppButtonVariant.filled,
                          onPressed: _openCreateCourt,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ScreenStateView(
                  state: _courtsController.state,
                  emptyTitle: 'No courts yet',
                  emptySubtitle: _courtsController.state == ScreenUiState.error
                      ? (_courtsController.errorMessage ??
                            'Unable to load courts.')
                      : 'Add the first court for this venue.',
                  onRetry: () => _courtsController.loadCourts(widget.venue.id),
                  content: Column(
                    children: [
                      for (final court in _courtsController.courts) ...[
                        _CourtCard(
                          court: court,
                          onEdit: () => _openEditCourt(court),
                          onDelete: _courtsController.canDeleteCourt
                              ? () => _deleteCourt(court)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.onEdit,
    required this.onDelete,
  });

  final Court court;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${court.courtType} • ${court.surface}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Capacity ${court.capacity} • ${court.openTime} - ${court.closeTime} • ${court.isActive ? 'Active' : 'Inactive'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
