import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../bookings/data/owner_bookings_api.dart';
import '../../../bookings/presentation/screens/bookings_list_screen.dart';
import '../../../venues/domain/models/court_models.dart';
import 'create_court_screen.dart';

// Spacing constants using design system
class _CourtDetailSpacing {
  static const double sectionGap = AppSpacing.lg;
  static const double elementGap = AppSpacing.xs2;
  static const double smallGap = AppSpacing.xs;
}

class CourtDetailsScreen extends StatefulWidget {
  const CourtDetailsScreen({
    super.key,
    required this.court,
    required this.venueName,
  });

  final Court court;
  final String venueName;

  @override
  State<CourtDetailsScreen> createState() => _CourtDetailsScreenState();
}

class _CourtDetailsScreenState extends State<CourtDetailsScreen> {
  final OwnerBookingsApi _bookingsApi = OwnerBookingsApi();

  ScreenUiState _statsState = ScreenUiState.loading;
  int _todayBookings = 0;
  double _todayRevenue = 0;
  int _weeklyBookings = 0;
  double _weeklyRevenue = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourtStatistics();
  }

  Future<void> _loadCourtStatistics() async {
    setState(() {
      _statsState = ScreenUiState.loading;
      _errorMessage = null;
    });

    try {
      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 7));

      // Get today's bookings
      final todayResponse = await _bookingsApi.listBookings(
        courtId: widget.court.id,
        date: today,
        status: 'CONFIRMED',
      );

      // Get this week's bookings
      final weeklyResponse = await _bookingsApi.listBookings(
        courtId: widget.court.id,
        status: 'CONFIRMED',
      );

      // Calculate today's stats
      final todayBookings = todayResponse.items.where((b) {
        if (b.bookingDate == null) return false;
        return _isSameDay(b.bookingDate!, today);
      }).length;

      final todayRevenue = todayResponse.items
          .where((b) {
            if (b.bookingDate == null) return false;
            return _isSameDay(b.bookingDate!, today);
          })
          .fold<int>(0, (sum, b) => sum + b.totalAmount);

      // Calculate weekly stats (last 7 days)
      final weeklyBookings = weeklyResponse.items.where((b) {
        if (b.bookingDate == null) return false;
        return b.bookingDate!.isAfter(weekAgo) ||
            b.bookingDate!.isAtSameMomentAs(weekAgo);
      }).length;

      final weeklyRevenue = weeklyResponse.items
          .where((b) {
            if (b.bookingDate == null) return false;
            return b.bookingDate!.isAfter(weekAgo) ||
                b.bookingDate!.isAtSameMomentAs(weekAgo);
          })
          .fold<int>(0, (sum, b) => sum + b.totalAmount);

      if (mounted) {
        setState(() {
          _todayBookings = todayBookings;
          _todayRevenue = todayRevenue / 100; // Convert from cents/paisa
          _weeklyBookings = weeklyBookings;
          _weeklyRevenue = weeklyRevenue / 100;
          _statsState = ScreenUiState.content;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _statsState = ScreenUiState.error;
        });
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _openEditCourt() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCourtScreen(
          venueId: widget.court.venueId,
          initialCourt: widget.court,
        ),
      ),
    );
    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BookingsListScreen(),
      ),
    );
  }

  void _openBlockSlots() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BookingsListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Collapsing App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _CourtHeroHeader(
                court: widget.court,
                venueName: widget.venueName,
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
                  onPressed: _openEditCourt,
                  icon: Icon(Icons.edit_rounded, color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadCourtStatistics,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Row
                    _StatusRow(court: widget.court),
                    const SizedBox(height: _CourtDetailSpacing.sectionGap),

                    // Quick Actions
                    _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: _CourtDetailSpacing.smallGap),
                    _QuickActionsRow(
                      onViewCalendar: _openCalendar,
                      onBlockSlots: _openBlockSlots,
                    ),
                    const SizedBox(height: _CourtDetailSpacing.sectionGap),

                    // Statistics Section
                    _SectionHeader(title: 'Statistics'),
                    const SizedBox(height: _CourtDetailSpacing.smallGap),
                    _StatisticsGrid(
                      state: _statsState,
                      todayBookings: _todayBookings,
                      todayRevenue: _todayRevenue,
                      weeklyBookings: _weeklyBookings,
                      weeklyRevenue: _weeklyRevenue,
                      errorMessage: _errorMessage,
                      onRetry: _loadCourtStatistics,
                    ),
                    const SizedBox(height: _CourtDetailSpacing.sectionGap),

                    // Operating Hours
                    _SectionHeader(title: 'Operating Hours'),
                    const SizedBox(height: _CourtDetailSpacing.smallGap),
                    _OperatingHoursCard(court: widget.court),
                    const SizedBox(height: _CourtDetailSpacing.sectionGap),

                    // Court Details
                    _SectionHeader(title: 'Court Details'),
                    const SizedBox(height: _CourtDetailSpacing.smallGap),
                    _CourtDetailsCard(court: widget.court),
                    const SizedBox(height: _CourtDetailSpacing.sectionGap),

                    // Maintenance History
                    _SectionHeader(title: 'Maintenance History'),
                    const SizedBox(height: _CourtDetailSpacing.smallGap),
                    _MaintenanceHistorySection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

class _CourtHeroHeader extends StatelessWidget {
  const _CourtHeroHeader({
    required this.court,
    required this.venueName,
  });

  final Court court;
  final String venueName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),

        // Court icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
        ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),

        // Court name and venue
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                court.name,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: AppFontWeights.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      venueName,
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
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.court});

  final Court court;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: _CourtDetailSpacing.smallGap,
      runSpacing: _CourtDetailSpacing.smallGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Active status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: court.isActive
                ? AppColors.success.withValues(alpha: 0.15)
                : colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                court.isActive ? Icons.check_circle_rounded : Icons.cancel,
                size: AppSpacing.sm - 2,
                color: court.isActive ? AppColors.success : colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                court.isActive ? 'Active' : 'Inactive',
                style: textTheme.labelMedium?.copyWith(
                  color: court.isActive ? AppColors.success : colorScheme.error,
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
            ],
          ),
        ),

        // Court type chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            court.courtType,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Surface chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            court.surface,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onViewCalendar,
    required this.onBlockSlots,
  });

  final VoidCallback onViewCalendar;
  final VoidCallback onBlockSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.calendar_month_rounded,
            label: 'View Calendar',
            color: colorScheme.primary,
            onTap: onViewCalendar,
          ),
        ),
        const SizedBox(width: _CourtDetailSpacing.elementGap),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.block_rounded,
            label: 'Block Slots',
            color: AppColors.warning,
            onTap: onBlockSlots,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSpacing.md),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({
    required this.state,
    required this.todayBookings,
    required this.todayRevenue,
    required this.weeklyBookings,
    required this.weeklyRevenue,
    this.errorMessage,
    this.onRetry,
  });

  final ScreenUiState state;
  final int todayBookings;
  final double todayRevenue;
  final int weeklyBookings;
  final double weeklyRevenue;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state == ScreenUiState.loading) {
      return Row(
        children: [
          Expanded(child: _buildShimmerCard(context)),
          const SizedBox(width: _CourtDetailSpacing.elementGap),
          Expanded(child: _buildShimmerCard(context)),
        ],
      );
    }

    if (state == ScreenUiState.error) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load statistics',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.event_available_rounded,
                iconColor: colorScheme.primary,
                label: "Today's Bookings",
                value: todayBookings.toString(),
                subtitle: 'Confirmed slots',
              ),
            ),
            const SizedBox(width: _CourtDetailSpacing.elementGap),
            Expanded(
              child: _StatCard(
                icon: Icons.payments_rounded,
                iconColor: AppColors.success,
                label: "Today's Revenue",
                value: 'Rs. ${_formatCurrency(todayRevenue)}',
                subtitle: 'From confirmed bookings',
              ),
            ),
          ],
        ),
        const SizedBox(height: _CourtDetailSpacing.elementGap),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up_rounded,
                iconColor: colorScheme.secondary,
                label: 'Weekly Bookings',
                value: weeklyBookings.toString(),
                subtitle: 'Last 7 days',
              ),
            ),
            const SizedBox(width: _CourtDetailSpacing.elementGap),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.success,
                label: 'Weekly Revenue',
                value: 'Rs. ${_formatCurrency(weeklyRevenue)}',
                subtitle: 'Last 7 days',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: AppFontWeights.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatingHoursCard extends StatelessWidget {
  const _OperatingHoursCard({required this.court});

  final Court court;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final openTime = _formatTime(court.openTime);
    final closeTime = _formatTime(court.closeTime);
    final slotDuration = court.slotDurationMins;

    // Calculate total hours and slots
    final openMinutes = _timeToMinutes(court.openTime);
    final closeMinutes = _timeToMinutes(court.closeTime);
    final totalMinutes = closeMinutes - openMinutes;
    final totalHours = totalMinutes / 60;
    final totalSlots = totalMinutes ~/ slotDuration;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time visualization bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.7),
                  colorScheme.primary.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    openTime,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${totalHours.toStringAsFixed(1)} hrs',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    closeTime,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details row
          Row(
            children: [
              Expanded(
                child: _TimeDetailItem(
                  icon: Icons.access_time_rounded,
                  label: 'Opens',
                  value: openTime,
                ),
              ),
              Expanded(
                child: _TimeDetailItem(
                  icon: Icons.schedule_rounded,
                  label: 'Closes',
                  value: closeTime,
                ),
              ),
              Expanded(
                child: _TimeDetailItem(
                  icon: Icons.timer_rounded,
                  label: 'Slot Duration',
                  value: '$slotDuration min',
                ),
              ),
              Expanded(
                child: _TimeDetailItem(
                  icon: Icons.view_agenda_rounded,
                  label: 'Daily Slots',
                  value: '$totalSlots',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Format in 12-hour format with AM/PM
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, hour, minute);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time24;
    }
  }

  int _timeToMinutes(String time24) {
    try {
      final parts = time24.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }
}

class _TimeDetailItem extends StatelessWidget {
  const _TimeDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: AppFontWeights.semiBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CourtDetailsCard extends StatelessWidget {
  const _CourtDetailsCard({required this.court});

  final Court court;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.people_outline,
            label: 'Capacity',
            value: '${court.capacity} players',
          ),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Min. Players',
            value: '${court.minPlayers} players',
          ),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          _DetailRow(
            icon: Icons.sports_soccer_outlined,
            label: 'Surface Type',
            value: court.surface,
          ),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Court Type',
            value: court.courtType,
          ),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          _DetailRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Court ID',
            value: court.id.substring(0, court.id.length > 8 ? 8 : court.id.length),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: AppFontWeights.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceHistorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Placeholder for maintenance history - to be implemented when API is ready
    return AppCard(
      child: Column(
        children: [
          // Empty state for maintenance history
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  size: 48,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Maintenance Records',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Maintenance history will appear here when available.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  onPressed: () {
                    // TODO: Implement add maintenance record
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maintenance tracking coming soon'),
                      ),
                    );
                  },
                  variant: AppButtonVariant.outlined,
                  icon: Icons.add_rounded,
                  label: 'Add Record',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
