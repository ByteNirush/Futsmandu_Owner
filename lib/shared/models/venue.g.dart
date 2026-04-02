// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Venue _$VenueFromJson(Map<String, dynamic> json) => _Venue(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  amenities: (json['amenities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  coverImage: json['coverImage'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$VenueToJson(_Venue instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'amenities': instance.amenities,
  'coverImage': instance.coverImage,
  'createdAt': instance.createdAt.toIso8601String(),
};
