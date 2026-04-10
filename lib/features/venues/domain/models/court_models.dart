class Court {
  const Court({
    required this.id,
    required this.venueId,
    required this.name,
    required this.courtType,
    required this.surface,
    required this.capacity,
    required this.minPlayers,
    required this.slotDurationMins,
    required this.openTime,
    required this.closeTime,
    this.isActive = true,
  });

  final String id;
  final String venueId;
  final String name;
  final String courtType;
  final String surface;
  final int capacity;
  final int minPlayers;
  final int slotDurationMins;
  final String openTime;
  final String closeTime;
  final bool isActive;

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: (json['id'] as String?) ?? '',
      venueId:
          (json['venue_id'] as String?) ?? (json['venueId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      courtType:
          (json['court_type'] as String?) ??
          (json['courtType'] as String?) ??
          '',
      surface: (json['surface'] as String?) ?? '',
      capacity: _toInt(json['capacity']),
      minPlayers: _toInt(json['min_players']),
      slotDurationMins: _toInt(json['slot_duration_mins']),
      openTime: (json['open_time'] as String?) ?? '',
      closeTime: (json['close_time'] as String?) ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  String get summary => '$surface • Capacity $capacity';

  static int _toInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

class CourtUpsertRequest {
  const CourtUpsertRequest({
    required this.name,
    required this.courtType,
    required this.surface,
    required this.capacity,
    required this.minPlayers,
    required this.slotDurationMins,
    required this.openTime,
    required this.closeTime,
  });

  final String name;
  final String courtType;
  final String surface;
  final int capacity;
  final int minPlayers;
  final int slotDurationMins;
  final String openTime;
  final String closeTime;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'court_type': courtType.trim(),
      'surface': surface.trim(),
      'capacity': capacity,
      'min_players': minPlayers,
      'slot_duration_mins': slotDurationMins,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final payload = toJson();
    payload.removeWhere((key, value) => value == null);
    return payload;
  }
}
