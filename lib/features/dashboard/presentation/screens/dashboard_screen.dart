import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../auth/domain/owner_auth_models.dart';
import '../../../auth/presentation/controllers/owner_auth_controller.dart';
import '../../data/dashboard_controller.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/summary_card.dart';
import '../widgets/upcoming_booking_item.dart';
import '../widgets/weekly_revenue_trend.dart';

class DashboardQuickAction {
  const DashboardQuickAction({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.quickActions = _defaultQuickActions,
    this.authController,
  });

  final List<DashboardQuickAction> quickActions;
  final OwnerAuthController? authController;

  static const _defaultQuickActions = <DashboardQuickAction>[];

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_onControllerChanged);
    _controller.loadOverview();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  ScreenUiState get _screenState {
    switch (_controller.loadState) {
      case DashboardLoadState.idle:
      case DashboardLoadState.loading:
        return ScreenUiState.loading;
      case DashboardLoadState.error:
        return ScreenUiState.error;
      case DashboardLoadState.loaded:
        return ScreenUiState.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _controller.overview;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: ScreenStateView(
        state: _screenState,
        emptyTitle: 'No overview data',
        emptySubtitle:
            'Dashboard metrics will appear here once you have bookings.',
        onRetry: _controller.refresh,
        content: RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xs),
            children: [
              const DashboardHeader(),
              const SizedBox(height: AppSpacing.md),
              if (widget.authController != null &&
                  widget.authController!.kycStatus !=
                      KycVerificationStatus.approved)
                _KycStatusBanner(
                  status: widget.authController!.kycStatus,
                  rejectionReason: widget.authController!.kycRejectionReason,
                  hasUploadedAnyKycDocument:
                      widget.authController!.hasUploadedAnyKycDocument,
                  onTap: () {
                    Navigator.of(context).pushNamed('/upload-documents');
                  },
                ),
              if (widget.authController != null &&
                  widget.authController!.kycStatus !=
                      KycVerificationStatus.approved)
                const SizedBox(height: AppSpacing.md),
              const _DashboardSectionHeader(title: 'Today\'s Overview'),
              const SizedBox(height: AppSpacing.sm),
              // Revenue — full-width card
              SummaryCard(
                title: 'Revenue Today',
                value: overview.revenueToday,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Bookings / Occupancy / Active Courts — 3 equal cards
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Bookings',
                        value: overview.bookingsToday.toString(),
                        icon: Icons.calendar_today_rounded,
                      ),
                    ),
                    Expanded(
                      child: SummaryCard(
                        title: 'Pending',
                        value: overview.pendingBookings.toString(),
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    ),
                    Expanded(
                      child: SummaryCard(
                        title: 'Active Courts',
                        value: overview.activeCourts.toString(),
                        icon: Icons.sports_soccer_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const WeeklyRevenueTrend(),
              const SizedBox(height: AppSpacing.md),
              const _DashboardSectionHeader(title: 'Quick Actions'),
              const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    for (int i = 0; i < widget.quickActions.length; i++)
                      Expanded(
                        child: QuickActionButton(
                          title: widget.quickActions[i].title,
                          icon: widget.quickActions[i].icon,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: widget.quickActions[i].builder,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _DashboardSectionHeader(title: 'Upcoming Bookings'),
              const SizedBox(height: AppSpacing.sm),
              Column(
                spacing: AppSpacing.sm,
                children: [
                  for (final booking in overview.upcomingBookings)
                    UpcomingBookingItem(
                      teamName: booking.customerName,
                      courtName: booking.courtName,
                      timeSlot: booking.timeSlot,
                      status: booking.status,
                    ),
                  if (overview.upcomingBookings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('No upcoming bookings for today'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KYC Banner (unchanged)
// ---------------------------------------------------------------------------

class _KycStatusBanner extends StatelessWidget {
  const _KycStatusBanner({
    required this.status,
    required this.rejectionReason,
    required this.hasUploadedAnyKycDocument,
    required this.onTap,
  });

  final KycVerificationStatus status;
  final String? rejectionReason;
  final bool hasUploadedAnyKycDocument;
  final VoidCallback onTap;

  bool get _isRejected => status == KycVerificationStatus.rejected;

  String get _title {
    if (_isRejected) {
      return 'KYC Rejected';
    }
    if (hasUploadedAnyKycDocument) {
      return 'KYC Under Review';
    }
    return 'Complete KYC Verification';
  }

  String get _subtitle {
    if (_isRejected) {
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty) {
        return 'Reason: ${rejectionReason!.trim()}';
      }
      return 'Your documents were not approved. Please update and resubmit.';
    }
    if (hasUploadedAnyKycDocument) {
      return 'Documents submitted. We will notify you once review is complete.';
    }
    return 'Upload required documents to unlock all features';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor = _isRejected
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final onContainerColor = _isRejected
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return AppCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              containerColor,
              containerColor.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isRejected
                      ? Icons.error_rounded
                      : Icons.hourglass_top_rounded,
                  color: onContainerColor,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: onContainerColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onContainerColor,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: onContainerColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header (unchanged)
// ---------------------------------------------------------------------------

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
