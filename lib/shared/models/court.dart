import 'package:freezed_annotation/freezed_annotation.dart';

part 'court.freezed.dart';
part 'court.g.dart';

/// Represents a playable court under a venue.
@freezed
abstract class Court with _$Court {
  const factory Court({
    required String id,
    required String venueId,
    required String name,
    required String surface,
    required int capacity,
    required int minPlayers,
    required DateTime openTime,
    required DateTime closeTime,
    required int slotDuration,
  }) = _Court;

  factory Court.fromJson(Map<String, dynamic> json) => _$CourtFromJson(json);
}