import 'package:flutter/foundation.dart';

import '../../../core/network/error_handler.dart';
import '../../analytics/data/owner_analytics_api.dart';
import '../../bookings/data/owner_bookings_api.dart';
import '../../venues/data/remote/owner_venues_remote_data_source.dart';
import '../../venues/domain/models/venue_models.dart';

/// Holds the fetched "Today's Overview" data.
class DashboardOverview {
  const DashboardOverview({
    required this.revenueToday,
    required this.bookingsToday,
    required this.pendingBookings,
    required this.activeCourts,
    required this.upcomingBookings,
  });

  /// Formatted revenue string, e.g. "NPR 28,500"
  final String revenueToday;

  /// Total confirmed bookings for today.
  final int bookingsToday;

  /// Total pending-payment bookings for today.
  final int pendingBookings;

  /// Total court count across all venues.
  final int activeCourts;

  /// Today's confirmed bookings for "Upcoming Bookings" list.
  final List<DashboardBookingItem> upcomingBookings;

  static const empty = DashboardOverview(
    revenueToday: '—',
    bookingsToday: 0,
    pendingBookings: 0,
    activeCourts: 0,
    upcomingBookings: [],
  );
}

/// A single booking row for the "Upcoming Bookings" section.
class DashboardBookingItem {
  const DashboardBookingItem({
    required this.customerName,
    required this.courtName,
    required this.timeSlot,
    required this.status,
  });

  final String customerName;
  final String courtName;
  final String timeSlot;
  final String status;
}

enum DashboardLoadState { idle, loading, loaded, error }

class DashboardController extends ChangeNotifier {
  DashboardController({
    OwnerAnalyticsApi? analyticsApi,
    OwnerBookingsApi? bookingsApi,
    OwnerVenuesRemoteDataSource? venuesDataSource,
  })  : _analyticsApi = analyticsApi ?? OwnerAnalyticsApi(),
        _bookingsApi = bookingsApi ?? OwnerBookingsApi(),
        _venuesDataSource = venuesDataSource ?? OwnerVenuesRemoteDataSource();

  final OwnerAnalyticsApi _analyticsApi;
  final OwnerBookingsApi _bookingsApi;
  final OwnerVenuesRemoteDataSource _venuesDataSource;

  DashboardLoadState _loadState = DashboardLoadState.idle;
  DashboardOverview _overview = DashboardOverview.empty;
  String? _errorMessage;

  DashboardLoadState get loadState => _loadState;
  DashboardOverview get overview => _overview;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _loadState == DashboardLoadState.loading;
  bool get hasError => _loadState == DashboardLoadState.error;
  bool get hasData => _loadState == DashboardLoadState.loaded;

  /// Fetch all data for the dashboard. Safe to call multiple times.
  Future<void> loadOverview() async {
    if (_loadState == DashboardLoadState.loading) return;

    _loadState = DashboardLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();

      // Fetch all three in parallel for speed.
      final results = await Future.wait([
        _analyticsApi.getSummary(from: today, to: today),
        _bookingsApi.listBookings(date: today, status: 'CONFIRMED'),
        _venuesDataSource.listVenues(),
      ]);

      final summary = results[0] as OwnerAnalyticsSummary;
      final bookingsPage = results[1] as BookingsPage;
      final venues = results[2] as List<Venue>;

      // Sum courts across all venues.
      final totalCourts = venues.fold<int>(0, (sum, v) => sum + v.courtsCount);

      // Build the upcoming booking items from the fetched list.
      final upcomingItems = bookingsPage.items.map((b) {
        final name =
            (b.offlineCustomerName?.isNotEmpty == true
                ? b.offlineCustomerName!
                : null) ??
            b.playerName ??
            'Unknown';
        final timeSlot =
            (b.startTime.isNotEmpty && b.endTime.isNotEmpty)
                ? '${b.startTime} - ${b.endTime}'
                : b.startTime;
        return DashboardBookingItem(
          customerName: name,
          courtName: b.courtName ?? '—',
          timeSlot: timeSlot,
          status: _capitalizeStatus(b.status),
        );
      }).toList(growable: false);

      final pendingCount =
          (summary.byStatus['PENDING_PAYMENT'] ?? 0) +
          (summary.byStatus['HELD'] ?? 0);

      _overview = DashboardOverview(
        revenueToday: _formatRevenue(summary.totalRevenueNpr),
        bookingsToday: summary.confirmedBookings,
        pendingBookings: pendingCount,
        activeCourts: totalCourts,
        upcomingBookings: upcomingItems,
      );

      _loadState = DashboardLoadState.loaded;
    } catch (error) {
      _errorMessage = ErrorHandler.messageFor(error);
      _loadState = DashboardLoadState.error;
    }

    notifyListeners();
  }

  /// Alias for pull-to-refresh.
  Future<void> refresh() => loadOverview();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Formats the backend-provided NPR string to "NPR X,XXX" style.
  String _formatRevenue(String totalRevenueNpr) {
    if (totalRevenueNpr.isEmpty || totalRevenueNpr == '0.00') {
      return 'NPR 0';
    }
    // Strip trailing .00 if it's a whole number; keep decimals otherwise.
    final numeric = double.tryParse(totalRevenueNpr);
    if (numeric == null) return 'NPR $totalRevenueNpr';
    final isWhole = numeric == numeric.truncateToDouble();
    final formatted = isWhole
        ? _addThousandSeparators(numeric.toInt().toString())
        : _addThousandSeparators(numeric.toStringAsFixed(2));
    return 'NPR $formatted';
  }

  String _addThousandSeparators(String value) {
    final parts = value.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }
    if (parts.length > 1) {
      buffer.write('.${parts[1]}');
    }
    return buffer.toString();
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() +
        status.substring(1).toLowerCase().replaceAll('_', ' ');
  }
}
