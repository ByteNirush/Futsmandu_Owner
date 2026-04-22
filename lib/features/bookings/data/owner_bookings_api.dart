import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';

class OwnerBookingsApi {
  OwnerBookingsApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<CourtCalendarResponse> getCourtCalendar({
    required String courtId,
    required DateTime date,
  }) async {
    final response = await _apiClient.get(
      OwnerApiConfig.courtCalendarEndpoint(courtId),
      queryParameters: {'date': _toDateOnly(date)},
    );

    final slots = _parseCalendarSlots(response);

    return CourtCalendarResponse(
      courtId: (response['courtId'] as String?) ?? courtId,
      date: (response['date'] as String?) ?? _toDateOnly(date),
      slots: slots,
    );
  }

  Future<CourtCalendarResponse> getBookingsCourtCalendar({
    required String courtId,
    required DateTime date,
  }) async {
    final response = await _apiClient.get(
      OwnerApiConfig.bookingCalendarEndpoint(courtId),
      queryParameters: {'date': _toDateOnly(date)},
    );

    final slots = _parseCalendarSlots(response);
    return CourtCalendarResponse(
      courtId: (response['courtId'] as String?) ?? courtId,
      date: (response['date'] as String?) ?? _toDateOnly(date),
      slots: slots,
    );
  }

  Future<CourtBlockResult> blockCourtSlot({
    required String courtId,
    required DateTime date,
    required String startTime,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.blockCourtSlotEndpoint(courtId),
      data: {
        'date': _toDateOnly(date),
        'startTime': startTime,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    return CourtBlockResult.fromJson(response);
  }

  Future<UnblockCourtResult> unblockCourtSlot({
    required String blockId,
  }) async {
    final response = await _apiClient.delete(
      OwnerApiConfig.unblockCourtSlotEndpoint(blockId),
    );
    return UnblockCourtResult.fromJson(response);
  }

  Future<OfflineBookingResult> createOfflineBooking({
    required String courtId,
    required DateTime bookingDate,
    required String startTime,
    required String bookingType,
    required String customerName,
    required String customerPhone,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.createOfflineBookingEndpoint,
      data: {
        'court_id': courtId,
        'booking_date': _toDateOnly(bookingDate),
        'start_time': startTime,
        'booking_type': bookingType,
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return OfflineBookingResult.fromJson(response);
  }

  Future<BookingsPage> listBookings({
    DateTime? date,
    String? courtId,
    String? status,
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      OwnerApiConfig.listBookingsEndpoint,
      queryParameters: {
        if (date != null) 'date': _toDateOnly(date),
        if (courtId != null && courtId.isNotEmpty) 'courtId': courtId,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
      },
    );

    final itemsRaw = response['data'];
    final metaRaw = response['meta'];
    final items = itemsRaw is List
        ? itemsRaw
              .whereType<Map<String, dynamic>>()
              .map(BookingListItem.fromJson)
              .toList(growable: false)
        : <BookingListItem>[];

    return BookingsPage(
      items: items,
      page: metaRaw is Map<String, dynamic> ? _asInt(metaRaw['page']) : page,
      limit: metaRaw is Map<String, dynamic> ? _asInt(metaRaw['limit']) : items.length,
      total: metaRaw is Map<String, dynamic> ? _asInt(metaRaw['total']) : items.length,
      totalPages: metaRaw is Map<String, dynamic> ? _asInt(metaRaw['totalPages']) : 1,
    );
  }

  Future<AttendanceResult> markAttendance({
    required String bookingId,
    required List<String> noShowIds,
  }) async {
    final response = await _apiClient.put(
      OwnerApiConfig.markAttendanceEndpoint(bookingId),
      data: {'no_show_ids': noShowIds},
    );
    return AttendanceResult.fromJson(response);
  }

  String _toDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<CourtCalendarSlot> _parseCalendarSlots(Map<String, dynamic> response) {
    final raw = response['slots'] ?? response['items'];
    if (raw is! List) {
      return const <CourtCalendarSlot>[];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CourtCalendarSlot.fromJson)
        .toList(growable: false);
  }
}

class CourtCalendarResponse {
  CourtCalendarResponse({
    required this.courtId,
    required this.date,
    required this.slots,
  });

  final String courtId;
  final String date;
  final List<CourtCalendarSlot> slots;
}

class CourtCalendarSlot {
  CourtCalendarSlot({
    required this.startTime,
    required this.endTime,
    required this.status,
    this.price,
    this.displayPrice,
    this.bookingId,
    this.playerName,
    this.bookingType,
  });

  final String startTime;
  final String endTime;
  final String status;
  final num? price;
  final String? displayPrice;
  final String? bookingId;
  final String? playerName;
  final String? bookingType;

  bool get isBlocked {
    final normalizedStatus = status.toUpperCase();
    final normalizedType = bookingType?.toLowerCase();
    return normalizedStatus == 'BLOCKED' ||
        normalizedType == 'offline_reserved';
  }

  factory CourtCalendarSlot.fromJson(Map<String, dynamic> json) {
    return CourtCalendarSlot(
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'AVAILABLE',
      price: json['price'] as num?,
      displayPrice: json['display_price'] as String?,
      bookingId: json['booking_id'] as String?,
      playerName: json['player_name'] as String?,
      bookingType: json['booking_type'] as String?,
    );
  }
}

class BookingListItem {
  BookingListItem({
    required this.id,
    required this.status,
    required this.bookingType,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.createdAt,
    this.offlineCustomerName,
    this.offlineCustomerPhone,
    this.playerId,
    this.playerName,
    this.courtName,
    this.venueName,
  });

  final String id;
  final String status;
  final String bookingType;
  final DateTime? bookingDate;
  final String startTime;
  final String endTime;
  final int totalAmount;
  final DateTime? createdAt;
  final String? offlineCustomerName;
  final String? offlineCustomerPhone;
  final String? playerId;
  final String? playerName;
  final String? courtName;
  final String? venueName;

  factory BookingListItem.fromJson(Map<String, dynamic> json) {
    return BookingListItem(
      id: (json['id'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'CONFIRMED',
      bookingType: (json['booking_source'] as String?) ?? '',
      bookingDate: DateTime.tryParse((json['booking_date'] as String?) ?? ''),
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      totalAmount: _asInt(json['total_amount']),
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      offlineCustomerName: json['offline_customer_name'] as String?,
      offlineCustomerPhone: json['offline_customer_phone'] as String?,
        playerId: json['player'] is Map<String, dynamic>
          ? (json['player'] as Map<String, dynamic>)['id'] as String?
          : null,
      playerName: json['player'] is Map<String, dynamic>
          ? (json['player'] as Map<String, dynamic>)['name'] as String?
          : null,
      courtName: json['court'] is Map<String, dynamic>
          ? (json['court'] as Map<String, dynamic>)['name'] as String?
          : null,
      venueName: json['venue'] is Map<String, dynamic>
          ? (json['venue'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CourtBlockResult {
  CourtBlockResult({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  final String id;
  final String startTime;
  final String endTime;
  final String status;

  factory CourtBlockResult.fromJson(Map<String, dynamic> json) {
    return CourtBlockResult(
      id: (json['id'] as String?) ?? '',
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
    );
  }
}

class UnblockCourtResult {
  UnblockCourtResult({required this.message});

  final String message;

  factory UnblockCourtResult.fromJson(Map<String, dynamic> json) {
    return UnblockCourtResult(
      message: (json['message'] as String?) ?? 'Slot unblocked',
    );
  }
}

class BookingsPage {
  BookingsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<BookingListItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class OfflineBookingResult {
  OfflineBookingResult({
    required this.id,
    required this.bookingType,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.bookingDate,
    required this.totalAmount,
    required this.offlineCustomerName,
  });

  final String id;
  final String bookingType;
  final String status;
  final String startTime;
  final String endTime;
  final DateTime? bookingDate;
  final int totalAmount;
  final String? offlineCustomerName;

  factory OfflineBookingResult.fromJson(Map<String, dynamic> json) {
    return OfflineBookingResult(
      id: (json['id'] as String?) ?? '',
      bookingType: (json['booking_type'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      bookingDate: DateTime.tryParse((json['booking_date'] as String?) ?? ''),
      totalAmount: _asInt(json['total_amount']),
      offlineCustomerName: json['offline_customer_name'] as String?,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AttendanceResult {
  AttendanceResult({required this.message, required this.noShowCount});

  final String message;
  final int noShowCount;

  factory AttendanceResult.fromJson(Map<String, dynamic> json) {
    return AttendanceResult(
      message: (json['message'] as String?) ?? '',
      noShowCount: _asInt(json['noShowCount']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
