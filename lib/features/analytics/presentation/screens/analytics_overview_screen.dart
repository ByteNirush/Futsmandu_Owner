import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_analytics_api.dart';

class AnalyticsOverviewScreen extends StatefulWidget {
  const AnalyticsOverviewScreen({super.key, this.state = ScreenUiState.content});

  final ScreenUiState state;

  @override
  State<AnalyticsOverviewScreen> createState() => _AnalyticsOverviewScreenState();
}

class _AnalyticsOverviewScreenState extends State<AnalyticsOverviewScreen> {
  final OwnerAnalyticsApi _analyticsApi = OwnerAnalyticsApi();

  bool _isLoading = true;
  String? _errorMessage;
  OwnerAnalyticsSummary? _summary;
  OwnerAnalyticsRevenue? _revenue;
  OwnerAnalyticsHeatmap? _heatmap;
  List<OwnerNoShowRateItem> _noShowRates = const [];
  String _groupBy = 'day';
  late DateTimeRange _selectedRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
      end: DateTime(now.year, now.month, now.day),
    );
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _analyticsApi.getSummary(
          from: _selectedRange.start,
          to: _selectedRange.end,
        ),
        _analyticsApi.getRevenue(
          from: _selectedRange.start,
          to: _selectedRange.end,
          groupBy: _groupBy,
        ),
        _analyticsApi.getHeatmap(
          from: _selectedRange.start,
          to: _selectedRange.end,
        ),
        _analyticsApi.getNoShowRate(
          from: _selectedRange.start,
          to: _selectedRange.end,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as OwnerAnalyticsSummary;
        _revenue = results[1] as OwnerAnalyticsRevenue;
        _heatmap = results[2] as OwnerAnalyticsHeatmap;
        _noShowRates = results[3] as List<OwnerNoShowRateItem>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load analytics.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateGrouping(String groupBy) async {
    if (_groupBy == groupBy) return;
    setState(() => _groupBy = groupBy);
    await _loadAnalytics();
  }

  String _formatDate(DateTime date) {
    final months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _rangeLabel() {
    return '${_formatDate(_selectedRange.start)} - ${_formatDate(_selectedRange.end)}';
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _selectedRange,
      saveText: 'Apply',
    );
    if (picked == null) return;

    setState(() {
      _selectedRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
    await _loadAnalytics();
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _revenueSection() {
    final revenue = _revenue;
    if (revenue == null || revenue.points.isEmpty) {
      return const AppCard(child: Text('No revenue trend data available.'));
    }

    var maxValue = 0;
    for (final point in revenue.points) {
      if (point.totalPaisa > maxValue) {
        maxValue = point.totalPaisa;
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'day', label: Text('Day')),
                  ButtonSegment(value: 'week', label: Text('Week')),
                  ButtonSegment(value: 'month', label: Text('Month')),
                ],
                selected: {_groupBy},
                onSelectionChanged: (value) {
                  _updateGrouping(value.first);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...revenue.points.map((point) {
            final ratio = maxValue > 0 ? point.totalPaisa / maxValue : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      point.period,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: ratio,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 72,
                    child: Text(
                      point.totalNpr,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _heatmapSection() {
    final heatmap = _heatmap;
    if (heatmap == null || heatmap.grid.isEmpty) {
      return const AppCard(child: Text('No occupancy heatmap data available.'));
    }

    var maxCount = 0;
    for (final row in heatmap.grid) {
      for (final count in row) {
        if (count > maxCount) {
          maxCount = count;
        }
      }
    }

    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings Heatmap',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Total bookings: ${heatmap.totalBookings}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 52),
                    for (var h = 0; h < 24; h++)
                      SizedBox(
                        width: 18,
                        child: Text(
                          h.toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                for (var day = 0; day < heatmap.grid.length && day < dayLabels.length; day++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            dayLabels[day],
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        for (final count in heatmap.grid[day])
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(
                                    alpha: maxCount == 0 ? 0 : (0.12 + (count / maxCount) * 0.78),
                                  ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noShowSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No-show Rate by Court',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_noShowRates.isEmpty)
            const Text('No no-show data yet.')
          else
            ..._noShowRates.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.courtName),
                          Text(item.venueName, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('${item.rate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state == ScreenUiState.content
        ? (_isLoading
            ? ScreenUiState.loading
            : (_errorMessage != null ? ScreenUiState.error : ScreenUiState.content))
        : widget.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: ScreenStateView(
        state: state,
        emptyTitle: 'No analytics data',
        emptySubtitle: _errorMessage ?? 'Analytics will appear here once you have bookings.',
        onRetry: _loadAnalytics,
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Range',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _rangeLabel(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_summary != null)
              Row(
                children: [
                  _summaryCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Confirmed Bookings',
                    value: _summary!.confirmedBookings.toString(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _summaryCard(
                    icon: Icons.payments_outlined,
                    title: 'Revenue',
                    value: _summary!.totalRevenueNpr,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            _revenueSection(),
            const SizedBox(height: AppSpacing.sm),
            _heatmapSection(),
            const SizedBox(height: AppSpacing.sm),
            _noShowSection(),
          ],
        ),
      ),
    );
  }
}
