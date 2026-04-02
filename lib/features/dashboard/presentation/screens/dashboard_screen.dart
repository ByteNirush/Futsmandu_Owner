import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/screen_state_view.dart';
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.state = ScreenUiState.content,
    this.quickActions = _defaultQuickActions,
  });

  final ScreenUiState state;
  final List<DashboardQuickAction> quickActions;

  static const _defaultQuickActions = <DashboardQuickAction>[];

  static const _revenueSummary = _SummaryItem(
    title: 'Revenue Today',
    value: 'NPR 28,500',
    icon: Icons.payments_outlined,
  );

  static const _otherSummaryItems = [
    _SummaryItem(
      title: 'Bookings',
      value: '18',
      icon: Icons.calendar_today_rounded,
    ),
    _SummaryItem(
      title: 'Occupancy',
      value: '76%',
      icon: Icons.stacked_bar_chart_rounded,
    ),
    _SummaryItem(
      title: 'Active Courts',
      value: '6',
      icon: Icons.sports_soccer_rounded,
    ),
  ];

  static const _upcomingBookings = [
    _UpcomingBookingData(
      teamName: 'Team Strikers',
      courtName: 'Court A',
      timeSlot: '7:00 PM - 8:00 PM',
      status: 'Confirmed',
    ),
    _UpcomingBookingData(
      teamName: 'FC Thunder',
      courtName: 'Court C',
      timeSlot: '8:00 PM - 9:00 PM',
      status: 'Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        state: state,
        emptyTitle: 'No overview data',
        emptySubtitle: 'Dashboard metrics will appear here once you have bookings.',
        content: RefreshIndicator(
          onRefresh: () async {
            // Refresh data
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xs),
            children: [
              const DashboardHeader(),
              const SizedBox(height: AppSpacing.md),
              const _DashboardSectionHeader(title: 'Today\'s Overview'),
              const SizedBox(height: AppSpacing.sm),
              SummaryCard(
                title: _revenueSummary.title,
                value: _revenueSummary.value,
                icon: _revenueSummary.icon,
              ),
              const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    for (int i = 0; i < _otherSummaryItems.length; i++)
                      Expanded(
                        child: SummaryCard(
                          title: _otherSummaryItems[i].title,
                          value: _otherSummaryItems[i].value,
                          icon: _otherSummaryItems[i].icon,
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
                    for (int i = 0; i < quickActions.length; i++)
                      Expanded(
                        child: QuickActionButton(
                          title: quickActions[i].title,
                          icon: quickActions[i].icon,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: quickActions[i].builder,
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
                  for (var i = 0; i < _upcomingBookings.length; i++)
                    UpcomingBookingItem(
                      teamName: _upcomingBookings[i].teamName,
                      courtName: _upcomingBookings[i].courtName,
                      timeSlot: _upcomingBookings[i].timeSlot,
                      status: _upcomingBookings[i].status,
                    ),
                  if (_upcomingBookings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('No upcoming bookings'),
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

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _UpcomingBookingData {
  const _UpcomingBookingData({
    required this.teamName,
    required this.courtName,
    required this.timeSlot,
    required this.status,
  });

  final String teamName;
  final String courtName;
  final String timeSlot;
  final String status;
}
