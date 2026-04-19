import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../auth/domain/owner_auth_models.dart';
import '../../../auth/presentation/controllers/owner_auth_controller.dart';
import '../../data/dashboard_controller.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/kyc_status_banner.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/revenue_sparkline_card.dart';
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
            // 16 px gutters on all sides; extra 8 px at the bottom so the last
            // item doesn't sit flush against the nav bar.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            children: [
              const DashboardHeader(),
              const SizedBox(height: AppSpacing.xs2),

              // KYC status banner (only when not approved)
              if (widget.authController != null &&
                  widget.authController!.kycStatus !=
                      KycVerificationStatus.approved) ...[
                KycStatusBanner(
                  status: widget.authController!.kycStatus,
                  rejectionReason: widget.authController!.kycRejectionReason,
                  hasUploadedAnyKycDocument:
                      widget.authController!.hasUploadedAnyKycDocument,
                  onTap: () {
                    Navigator.of(context).pushNamed('/upload-documents');
                  },
                ),
                const SizedBox(height: AppSpacing.xs2),
              ],

              // ── Today's Overview ──────────────────────────────────────────
              const _SectionHeader(title: "Today's Overview"),
              const SizedBox(height: AppSpacing.xs),

              // Revenue — full-width sparkline card
              RevenueSparklineCard(
                title: 'Revenue Today',
                value: overview.revenueToday,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Bookings / Pending / Active Courts — Masonry Wrap
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - (AppSpacing.sm * 3)) / 2,
                    child: SummaryCard(
                      title: 'Bookings',
                      value: overview.bookingsToday.toString(),
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - (AppSpacing.sm * 3)) / 2,
                    child: SummaryCard(
                      title: 'Pending',
                      value: overview.pendingBookings.toString(),
                      icon: Icons.hourglass_bottom_rounded,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - (AppSpacing.sm * 2),
                    child: SummaryCard(
                      title: 'Active Courts',
                      value: overview.activeCourts.toString(),
                      icon: Icons.sports_soccer_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Weekly Trend ──────────────────────────────────────────────
              const WeeklyRevenueTrend(),
              const SizedBox(height: AppSpacing.xs2),

              // ── Quick Actions ─────────────────────────────────────────────
              if (widget.quickActions.isNotEmpty) ...[
                const _SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: AppSpacing.xs),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < widget.quickActions.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
              ],

              // ── Upcoming Bookings ─────────────────────────────────────────
              const _SectionHeader(title: 'Upcoming Bookings'),
              const SizedBox(height: AppSpacing.xs),

              if (overview.upcomingBookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Center(
                    child: Text(
                      'No upcoming bookings for today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                ...List.generate(overview.upcomingBookings.length, (i) {
                  final booking = overview.upcomingBookings[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < overview.upcomingBookings.length - 1
                          ? AppSpacing.xs
                          : 0,
                    ),
                    child: UpcomingBookingItem(
                      teamName: booking.customerName,
                      courtName: booking.courtName,
                      timeSlot: booking.timeSlot,
                      status: booking.status,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// KYC Banner moved to its own widget.

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: AppFontWeights.bold,
                letterSpacing: -0.1,
              ),
        ),
      ],
    );
  }
}
