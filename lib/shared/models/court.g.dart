// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'court.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Court _$CourtFromJson(Map<String, dynamic> json) => _Court(
  id: json['id'] as String,
  venueId: json['venueId'] as String,
  name: json['name'] as String,
  surface: json['surface'] as String,
  capacity: (json['capacity'] as num).toInt(),
  minPlayers: (json['minPlayers'] as num).toInt(),
  openTime: DateTime.parse(json['openTime'] as String),
  closeTime: DateTime.parse(json['closeTime'] as String),
  slotDuration: (json['slotDuration'] as num).toInt(),
);

Map<String, dynamic> _$CourtToJson(_Court instance) => <String, dynamic>{
  'id': instance.id,
  'venueId': instance.venueId,
  'name': instance.name,
  'surface': instance.surface,
  'capacity': instance.capacity,
  'minPlayers': instance.minPlayers,
  'openTime': instance.openTime.toIso8601String(),
  'closeTime': instance.closeTime.toIso8601String(),
  'slotDuration': instance.slotDuration,
};
