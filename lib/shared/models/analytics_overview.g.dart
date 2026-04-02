// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyticsOverview _$AnalyticsOverviewFromJson(Map<String, dynamic> json) =>
    _AnalyticsOverview(
      todayBookings: (json['todayBookings'] as num).toInt(),
      todayRevenue: (json['todayRevenue'] as num).toDouble(),
      occupancyRate: (json['occupancyRate'] as num).toDouble(),
      activeCourts: (json['activeCourts'] as num).toInt(),
    );

Map<String, dynamic> _$AnalyticsOverviewToJson(_AnalyticsOverview instance) =>
    <String, dynamic>{
      'todayBookings': instance.todayBookings,
      'todayRevenue': instance.todayRevenue,
      'occupancyRate': instance.occupancyRate,
      'activeCourts': instance.activeCourts,
    };
