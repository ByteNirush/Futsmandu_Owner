import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_overview.freezed.dart';
part 'analytics_overview.g.dart';

/// Represents aggregated analytics shown on dashboard.
@freezed
abstract class AnalyticsOverview with _$AnalyticsOverview {
  const factory AnalyticsOverview({
    required int todayBookings,
    required double todayRevenue,
    required double occupancyRate,
    required int activeCourts,
  }) = _AnalyticsOverview;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsOverviewFromJson(json);
}