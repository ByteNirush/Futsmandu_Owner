import 'package:freezed_annotation/freezed_annotation.dart';

import 'booking.dart';

part 'upcoming_booking.freezed.dart';
part 'upcoming_booking.g.dart';

/// Represents a booking card item shown in upcoming bookings list.
@freezed
abstract class UpcomingBooking with _$UpcomingBooking {
  const factory UpcomingBooking({
    required String teamName,
    required String courtName,
    required DateTime startTime,
    required DateTime endTime,
    required BookingStatus status,
  }) = _UpcomingBooking;

  factory UpcomingBooking.fromJson(Map<String, dynamic> json) =>
      _$UpcomingBookingFromJson(json);
}