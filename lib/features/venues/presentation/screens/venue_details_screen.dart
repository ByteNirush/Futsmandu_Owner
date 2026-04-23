import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../shared/widgets/safe_network_image.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../courts/presentation/screens/create_court_screen.dart';
import '../../../media/service/uploaded_image_cache.dart';
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
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _courtsController.loadCourts(widget.venue.id);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _courtsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Builds the list of images for the carousel:
  /// cover image (if any) + any gallery images cached from the current session.
  List<String> get _carouselImages {
    final images = <String>[];
    if (widget.venue.imageUrl != null && widget.venue.imageUrl!.isNotEmpty) {
      images.add(widget.venue.imageUrl!);
    }
    // Append gallery images from in-memory cache for this session.
    final cached = uploadedImageCache.getAll();
    for (final img in cached) {
      final url = img.displayUrl;
      if (url != null && url.isNotEmpty && !images.contains(url)) {
        images.add(url);
      }
    }
    return images;
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

  Future<void> _showFullImage({String? imageUrl}) async {
    final url = imageUrl ?? widget.venue.imageUrl;
    if (url == null || url.isEmpty) return;

    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: url.startsWith('data:')
                  ? Image.memory(
                      Uri.parse(url).data!.contentAsBytes(),
                      fit: BoxFit.contain,
                    )
                  : SafeNetworkImage(
                      url: url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCourt(Court court) async {
    if (!_courtsController.canDeleteCourt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete court.')),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _courtsController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Collapsing App Bar with Swipeable Image Carousel ───────
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: _VenueCoverCarousel(
                    imageUrls: _carouselImages,
                    venue: widget.venue,
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    onExpand: (url) => _showFullImage(imageUrl: url),
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _openEditVenue,
                      icon: Icon(Icons.edit_rounded, color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () => _courtsController.loadCourts(widget.venue.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description Section
                        if (widget.venue.description.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.cardPadding),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(title: 'About'),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  widget.venue.description,
                                  style: textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Location Section
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(title: 'Location'),
                              const SizedBox(height: AppSpacing.sm),
                              _LocationCard(venue: widget.venue),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Amenities Section
                        if (widget.venue.amenities.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.cardPadding),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(title: 'Amenities'),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.xs2,
                                  runSpacing: AppSpacing.xs2,
                                  children: widget.venue.amenities.map((amenity) {
                                    return _AmenityChip(amenity: amenity);
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Status Section
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(title: 'Status'),
                              const SizedBox(height: AppSpacing.sm),
                              _StatusGrid(venue: widget.venue),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Courts Section Header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Courts',
                                    style: textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_courtsController.courts.length} court${_courtsController.courts.length == 1 ? '' : 's'} available',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _openCreateCourt,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Court'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Courts List
                        ScreenStateView(
                          state: _courtsController.state,
                          emptyTitle: 'No courts yet',
                          emptySubtitle: _courtsController.state == ScreenUiState.error
                              ? (_courtsController.errorMessage ?? 'Unable to load courts.')
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
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.displayAddress,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${venue.address.city}, ${venue.address.district}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.my_location_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Lat: ${venue.latitude.toStringAsFixed(6)}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.my_location_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Lng: ${venue.longitude.toStringAsFixed(6)}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.amenity});

  final String amenity;

  IconData _getIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('park')) return Icons.local_parking_rounded;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('food') || lower.contains('cafe')) return Icons.restaurant_rounded;
    if (lower.contains('seating') || lower.contains('lounge')) return Icons.chair_rounded;
    if (lower.contains('light') || lower.contains('flood')) return Icons.light_rounded;
    if (lower.contains('shoe') || lower.contains('equipment')) return Icons.sports_rounded;
    if (lower.contains('water') || lower.contains('drink')) return Icons.water_drop_outlined;
    if (lower.contains('restroom') || lower.contains('toilet')) return Icons.wc_outlined;
    if (lower.contains('shower')) return Icons.shower_outlined;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(amenity),
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            amenity,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatusBadge(
          label: venue.isVerified ? 'Verified' : 'Pending',
          isActive: venue.isVerified,
          activeColor: Colors.green,
          inactiveColor: Colors.orange,
        ),
        _StatusBadge(
          label: venue.isActive ? 'Active' : 'Inactive',
          isActive: venue.isActive,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey,
        ),
        Container(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${venue.courtsCount} court${venue.courtsCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: AppFontWeights.regular,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          fontWeight: AppFontWeights.semiBold,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================================
// _VenueCoverCarousel
// Swipeable image slider for the venue details hero area.
// • Shows cover image first, then any gallery images from the in-memory cache.
// • Animated dot indicators + prev/next arrows (hidden when only 1 image).
// • Gradient overlay + venue name / verification badge.
// • Tap-to-expand button opens current slide fullscreen.
// ============================================================================

class _VenueCoverCarousel extends StatelessWidget {
  const _VenueCoverCarousel({
    required this.imageUrls,
    required this.venue,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onExpand,
  });

  final List<String> imageUrls;
  final Venue venue;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onExpand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasImages = imageUrls.isNotEmpty;
    final multipleImages = imageUrls.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Page view ──────────────────────────────────────────────────────
        if (hasImages)
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final url = imageUrls[index];
              return url.startsWith('data:')
                  ? Image.memory(
                      Uri.parse(url).data!.contentAsBytes(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : SafeNetworkImage(
                      url: url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    );
            },
          )
        else
          // No images at all — show placeholder
          Container(
            color: colorScheme.primaryContainer,
            child: Center(
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),

        // ── Gradient overlay ───────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),

        // ── Venue name + badge overlay ─────────────────────────────────────
        Positioned(
          bottom: multipleImages ? 40 : 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!venue.isVerified)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pending_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pending Verification',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: AppFontWeights.semiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                venue.name,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      venue.displayAddress,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Dot indicators (multi-image only) ─────────────────────────────
        if (multipleImages)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                final isActive = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                );
              }),
            ),
          ),

        // ── Left chevron (multi-image only) ───────────────────────────────
        if (multipleImages && currentPage > 0)
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

        // ── Right chevron (multi-image only) ──────────────────────────────
        if (multipleImages && currentPage < imageUrls.length - 1)
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

        // ── Tap-to-expand button ──────────────────────────────────────────
        if (hasImages)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 20,
            child: GestureDetector(
              onTap: () {
                final url = imageUrls[currentPage.clamp(0, imageUrls.length - 1)];
                onExpand(url);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      multipleImages
                          ? '${currentPage + 1} / ${imageUrls.length}'
                          : 'Tap to expand',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          court.name,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: court.isActive
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                court.isActive ? 'Active' : 'Inactive',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: AppFontWeights.semiBold,
                                  color: court.isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${court.courtType} • ${court.surface}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${court.openTime} - ${court.closeTime} • Capacity ${court.capacity}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
