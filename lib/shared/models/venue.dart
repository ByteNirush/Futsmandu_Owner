import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

/// Represents a futsal venue managed by the owner.
@freezed
abstract class Venue with _$Venue {
  const factory Venue({
    required String id,
    required String name,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> amenities,
    required String coverImage,
    required DateTime createdAt,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}