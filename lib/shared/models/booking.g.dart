// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Booking _$BookingFromJson(Map<String, dynamic> json) => _Booking(
  id: json['id'] as String,
  venueId: json['venueId'] as String,
  courtId: json['courtId'] as String,
  teamName: json['teamName'] as String,
  bookingDate: DateTime.parse(json['bookingDate'] as String),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  status: $enumDecode(_$BookingStatusEnumMap, json['status']),
  paymentStatus: $enumDecode(
    _$BookingPaymentStatusEnumMap,
    json['paymentStatus'],
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$BookingToJson(_Booking instance) => <String, dynamic>{
  'id': instance.id,
  'venueId': instance.venueId,
  'courtId': instance.courtId,
  'teamName': instance.teamName,
  'bookingDate': instance.bookingDate.toIso8601String(),
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'status': _$BookingStatusEnumMap[instance.status]!,
  'paymentStatus': _$BookingPaymentStatusEnumMap[instance.paymentStatus]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$BookingStatusEnumMap = {
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
  BookingStatus.noShow: 'noShow',
};

const _$BookingPaymentStatusEnumMap = {
  BookingPaymentStatus.pending: 'pending',
  BookingPaymentStatus.paid: 'paid',
  BookingPaymentStatus.refunded: 'refunded',
  BookingPaymentStatus.failed: 'failed',
};
