import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../shared/widgets/safe_network_image.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../courts/presentation/screens/court_details_screen.dart';
import '../../../courts/presentation/screens/create_court_screen.dart';
import '../../../media/model/media_upload_models.dart';
import '../../../media/service/owner_media_api.dart';
import '../../../media/service/uploaded_image_cache.dart';
import '../../domain/models/court_models.dart';
import '../../domain/models/venue_models.dart';
import '../controllers/venue_courts_controller.dart';
import 'create_venue_screen.dart';

// Spacing constants using design system
class _VenueDetailSpacing {
  static const double sectionGap = AppSpacing.lg;
  static const double subSectionGap = AppSpacing.sm;
  static const double elementGap = AppSpacing.xs;
  static const double smallGap = AppSpacing.xxs;
}

class VenueDetailsScreen extends StatefulWidget {
  const VenueDetailsScreen({super.key, required this.venue});

  final Venue venue;

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  final VenueCourtsController _courtsController = VenueCourtsController();
  final OwnerMediaApi _mediaApi = OwnerMediaApi();
  late final PageController _pageController;
  int _currentPage = 0;
  List<VenueGalleryImage> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    _courtsController.loadCourts(widget.venue.id);
    _pageController = PageController();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    try {
      final images = await _mediaApi.fetchVenueGallery(widget.venue.id);
      if (mounted) {
        setState(() => _galleryImages = images);
      }
    } catch (e) {
      // Silently fail - gallery images are not critical
      debugPrint('Failed to load gallery images: $e');
    }
  }

  @override
  void dispose() {
    _courtsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Builds the list of images for the carousel:
  /// cover image (if any) + gallery images from API + any cached from current session.
  List<String> get _carouselImages {
    final images = <String>[];
    if (widget.venue.imageUrl != null && widget.venue.imageUrl!.isNotEmpty) {
      images.add(widget.venue.imageUrl!);
    }
    // Add gallery images from API
    for (final img in _galleryImages) {
      final url = img.displayUrl;
      if (url.isNotEmpty && !images.contains(url)) {
        images.add(url);
      }
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

  Future<void> _openCourtDetails(Court court) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CourtDetailsScreen(
          court: court,
          venueName: widget.venue.name,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _courtsController.loadCourts(widget.venue.id);
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
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Status & Meta Row ────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _StatusRow(venue: widget.venue),
                            const Spacer(),
                            _MetaChip(
                              icon: Icons.sports_soccer_rounded,
                              label: '${widget.venue.courtsCount} Courts',
                            ),
                          ],
                        ),

                        const SizedBox(height: _VenueDetailSpacing.sectionGap),

                        // ── About Section ──────────────────────────────────────────
                        if (widget.venue.description.isNotEmpty) ...[
                          _SectionHeader(title: 'About'),
                          const SizedBox(height: _VenueDetailSpacing.smallGap),
                          Text(
                            widget.venue.description,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: _VenueDetailSpacing.sectionGap),
                        ],

                        // ── Location Section ───────────────────────────────────────
                        _SectionHeader(title: 'Location'),
                        const SizedBox(height: _VenueDetailSpacing.smallGap),
                        _LocationRow(venue: widget.venue),
                        const SizedBox(height: _VenueDetailSpacing.sectionGap),

                        // ── Amenities Section ──────────────────────────────────────
                        if (widget.venue.amenities.isNotEmpty) ...[
                          _SectionHeader(title: 'Amenities'),
                          const SizedBox(height: _VenueDetailSpacing.smallGap),
                          Wrap(
                            spacing: _VenueDetailSpacing.elementGap,
                            runSpacing: _VenueDetailSpacing.smallGap,
                            children: widget.venue.amenities.map((amenity) {
                              return _AmenityChip(label: amenity);
                            }).toList(),
                          ),
                          const SizedBox(height: _VenueDetailSpacing.sectionGap),
                        ],

                        // Courts Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionHeader(title: 'Courts'),
                            FilledButton.icon(
                              onPressed: _openCreateCourt,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Court'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: textTheme.labelMedium?.copyWith(fontWeight: AppFontWeights.semiBold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _VenueDetailSpacing.smallGap),
                        Text(
                          '${_courtsController.courts.length} court${_courtsController.courts.length == 1 ? '' : 's'} available',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: _VenueDetailSpacing.subSectionGap),

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
                                  onTap: () => _openCourtDetails(court),
                                  onEdit: () => _openEditCourt(court),
                                  onDelete: _courtsController.canDeleteCourt
                                      ? () => _deleteCourt(court)
                                      : null,
                                ),
                                const SizedBox(height: _VenueDetailSpacing.elementGap),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: AppFontWeights.semiBold,
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: _VenueDetailSpacing.smallGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venue.displayAddress,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
              Text(
                '${venue.address.city}, ${venue.address.district}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: _VenueDetailSpacing.smallGap,
      runSpacing: _VenueDetailSpacing.smallGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Active status text
        Text(
          venue.isActive ? 'Active' : 'Inactive',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: AppFontWeights.semiBold,
            color: venue.isActive ? AppColors.success : colorScheme.onSurfaceVariant,
          ),
        ),
        // Verified badge
        if (venue.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: AppSpacing.xs2,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  'Verified',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: AppFontWeights.semiBold,
                  ),
                ),
              ],
            ),
          ),
      ],
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
                    color: AppColors.warning.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
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
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
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
                  borderRadius: BorderRadius.circular(AppRadius.xl),
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
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Court court;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _VenueDetailSpacing.elementGap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Court icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.sports_soccer_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: _VenueDetailSpacing.subSectionGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court name
                  Text(
                    court.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                  const SizedBox(height: _VenueDetailSpacing.smallGap),
                  // Status and type row
                  Row(
                    children: [
                      Text(
                        court.isActive ? 'Active' : 'Inactive',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: AppFontWeights.semiBold,
                          color: court.isActive ? AppColors.success : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${court.courtType}, ${court.surface}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _VenueDetailSpacing.smallGap),
                  // Hours and capacity
                  Text(
                    '${court.openTime} - ${court.closeTime} • Capacity ${court.capacity}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit action
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                // Delete action
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
