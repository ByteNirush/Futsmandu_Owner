import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';

class OwnerAnalyticsApi {
  OwnerAnalyticsApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<OwnerAnalyticsSummary> getSummary({
    DateTime? from,
    DateTime? to,
    String? courtId,
  }) async {
    final response = await _apiClient.get(
      '${OwnerApiConfig.analyticsEndpoint}/summary',
      queryParameters: {
        if (from != null) 'from': _toDateOnly(from),
        if (to != null) 'to': _toDateOnly(to),
        if (courtId != null && courtId.isNotEmpty) 'courtId': courtId,
      },
    );
    return OwnerAnalyticsSummary.fromJson(response);
  }

  Future<OwnerAnalyticsHeatmap> getHeatmap({
    DateTime? from,
    DateTime? to,
    String? courtId,
  }) async {
    final response = await _apiClient.get(
      '${OwnerApiConfig.analyticsEndpoint}/heatmap',
      queryParameters: {
        if (from != null) 'from': _toDateOnly(from),
        if (to != null) 'to': _toDateOnly(to),
        if (courtId != null && courtId.isNotEmpty) 'courtId': courtId,
      },
    );
    return OwnerAnalyticsHeatmap.fromJson(response);
  }

  Future<OwnerAnalyticsRevenue> getRevenue({
    DateTime? from,
    DateTime? to,
    String? courtId,
    String groupBy = 'day',
  }) async {
    final response = await _apiClient.get(
      '${OwnerApiConfig.analyticsEndpoint}/revenue',
      queryParameters: {
        if (from != null) 'from': _toDateOnly(from),
        if (to != null) 'to': _toDateOnly(to),
        if (courtId != null && courtId.isNotEmpty) 'courtId': courtId,
        'groupBy': groupBy,
      },
    );
    return OwnerAnalyticsRevenue.fromJson(response);
  }

  Future<List<OwnerNoShowRateItem>> getNoShowRate({
    DateTime? from,
    DateTime? to,
    String? courtId,
  }) async {
    final response = await _apiClient.get(
      '${OwnerApiConfig.analyticsEndpoint}/no-show-rate',
      queryParameters: {
        if (from != null) 'from': _toDateOnly(from),
        if (to != null) 'to': _toDateOnly(to),
        if (courtId != null && courtId.isNotEmpty) 'courtId': courtId,
      },
    );

    final items = response['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(OwnerNoShowRateItem.fromJson)
        .toList(growable: false);
  }

  String _toDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class OwnerAnalyticsSummary {
  OwnerAnalyticsSummary({
    required this.totalRevenuePaisa,
    required this.totalRevenueNpr,
    required this.confirmedBookings,
    required this.avgBookingValue,
    required this.byStatus,
  });

  final int totalRevenuePaisa;
  final String totalRevenueNpr;
  final int confirmedBookings;
  final int avgBookingValue;
  final Map<String, int> byStatus;

  factory OwnerAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final byStatusRaw = json['byStatus'];
    final byStatus = <String, int>{};
    if (byStatusRaw is Map) {
      byStatusRaw.forEach((key, value) {
        byStatus[key.toString()] = _asInt(value);
      });
    }

    return OwnerAnalyticsSummary(
      totalRevenuePaisa: _asInt(json['totalRevenuePaisa']),
      totalRevenueNpr: (json['totalRevenueNPR'] as String?) ?? '',
      confirmedBookings: _asInt(json['confirmedBookings']),
      avgBookingValue: _asInt(json['avgBookingValue']),
      byStatus: byStatus,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class OwnerAnalyticsHeatmap {
  OwnerAnalyticsHeatmap({
    required this.grid,
    required this.totalBookings,
  });

  final List<List<int>> grid;
  final int totalBookings;

  factory OwnerAnalyticsHeatmap.fromJson(Map<String, dynamic> json) {
    final rawGrid = json['grid'];
    final parsedGrid = <List<int>>[];
    if (rawGrid is List) {
      for (final row in rawGrid) {
        if (row is List) {
          parsedGrid.add(
            row.map((value) => value is int ? value : int.tryParse(value.toString()) ?? 0).toList(growable: false),
          );
        }
      }
    }
    return OwnerAnalyticsHeatmap(
      grid: parsedGrid,
      totalBookings: _asInt(json['totalBookings']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class OwnerAnalyticsRevenue {
  OwnerAnalyticsRevenue({
    required this.groupBy,
    required this.points,
  });

  final String groupBy;
  final List<OwnerRevenuePoint> points;

  factory OwnerAnalyticsRevenue.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['data'];
    final points = rawPoints is List
        ? rawPoints
              .whereType<Map<String, dynamic>>()
              .map(OwnerRevenuePoint.fromJson)
              .toList(growable: false)
        : <OwnerRevenuePoint>[];

    return OwnerAnalyticsRevenue(
      groupBy: (json['groupBy'] as String?) ?? 'day',
      points: points,
    );
  }
}

class OwnerRevenuePoint {
  OwnerRevenuePoint({
    required this.period,
    required this.totalPaisa,
    required this.totalNpr,
  });

  final String period;
  final int totalPaisa;
  final String totalNpr;

  factory OwnerRevenuePoint.fromJson(Map<String, dynamic> json) {
    return OwnerRevenuePoint(
      period: (json['period'] as String?) ?? '',
      totalPaisa: _asInt(json['totalPaisa']),
      totalNpr: (json['totalNPR'] as String?) ?? '',
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class OwnerNoShowRateItem {
  OwnerNoShowRateItem({
    required this.courtId,
    required this.courtName,
    required this.venueName,
    required this.total,
    required this.noShows,
    required this.rate,
  });

  final String courtId;
  final String courtName;
  final String venueName;
  final int total;
  final int noShows;
  final double rate;

  factory OwnerNoShowRateItem.fromJson(Map<String, dynamic> json) {
    return OwnerNoShowRateItem(
      courtId: (json['courtId'] as String?) ?? '',
      courtName: (json['courtName'] as String?) ?? '',
      venueName: (json['venueName'] as String?) ?? '',
      total: _asInt(json['total']),
      noShows: _asInt(json['noShows']),
      rate: _asDouble(json['rate']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
