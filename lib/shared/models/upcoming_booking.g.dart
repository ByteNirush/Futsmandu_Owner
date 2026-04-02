// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpcomingBooking _$UpcomingBookingFromJson(Map<String, dynamic> json) =>
    _UpcomingBooking(
      teamName: json['teamName'] as String,
      courtName: json['courtName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$UpcomingBookingToJson(_UpcomingBooking instance) =>
    <String, dynamic>{
      'teamName': instance.teamName,
      'courtName': instance.courtName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'status': _$BookingStatusEnumMap[instance.status]!,
    };

const _$BookingStatusEnumMap = {
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
  BookingStatus.noShow: 'noShow',
};
