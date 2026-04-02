import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

/// Represents the lifecycle status of a booking.
enum BookingStatus {
  confirmed,
  cancelled,
  completed,
  noShow,
}

/// Represents payment state of a booking.
enum BookingPaymentStatus {
  pending,
  paid,
  refunded,
  failed,
}

/// Represents a team booking for a specific court and time slot.
@freezed
abstract class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String venueId,
    required String courtId,
    required String teamName,
    required DateTime bookingDate,
    required DateTime startTime,
    required DateTime endTime,
    required BookingStatus status,
    required BookingPaymentStatus paymentStatus,
    required DateTime createdAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
}