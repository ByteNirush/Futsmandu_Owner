class VenueAddress {
  const VenueAddress({
    required this.street,
    required this.city,
    required this.district,
  });

  final String street;
  final String city;
  final String district;

  String get formatted => '$street, $city, $district';

  factory VenueAddress.fromJson(Map<String, dynamic> json) {
    return VenueAddress(
      street: _toStringOrEmpty(json['street']),
      city: _toStringOrEmpty(json['city']),
      district: _toStringOrEmpty(json['district']),
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'district': district,
  };
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.fullRefundHours,
    required this.partialRefundHours,
    required this.partialRefundPct,
    this.imageUrl,
    this.courtsCount = 0,
    this.isVerified = false,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final VenueAddress address;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final int fullRefundHours;
  final int partialRefundHours;
  final int partialRefundPct;
  final String? imageUrl;
  final int courtsCount;
  final bool isVerified;
  final bool isActive;

  factory Venue.fromJson(Map<String, dynamic> json) {
    final addressJson = json['address'];
    final address = addressJson is Map
        ? VenueAddress.fromJson(Map<String, dynamic>.from(addressJson))
        : const VenueAddress(street: '', city: '', district: '');

    return Venue(
      id: _toStringOrEmpty(json['id']),
      name: _toStringOrEmpty(json['name']),
      description: _toStringOrEmpty(json['description']),
      address: address,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      amenities: _asStringList(json['amenities']),
      fullRefundHours: _toInt(json['full_refund_hours']),
      partialRefundHours: _toInt(json['partial_refund_hours']),
      partialRefundPct: _toInt(json['partial_refund_pct']),
      imageUrl:
          _toNullableString(json['cover_image_url']) ??
          _toNullableString(json['image_url']) ??
          _toNullableString(json['imageUrl']),
      courtsCount: _toInt(
        (json['_count'] is Map<String, dynamic>)
            ? (json['_count'] as Map<String, dynamic>)['courts']
            : (json['courts_count'] ?? json['courtsCount'] ?? json['total_courts']),
      ),
      isVerified: _toBool(json['is_verified'] ?? json['isVerified']),
      isActive: _toBool(json['is_active'] ?? json['isActive'], fallback: true),
    );
  }

  String get displayAddress => address.formatted;

  static List<String> _asStringList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .map((entry) => entry?.toString().trim())
        .whereType<String>()
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static int _toInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static double _toDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static bool _toBool(Object? raw, {bool fallback = false}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final normalized = raw?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }
}

String _toStringOrEmpty(Object? raw) => raw?.toString() ?? '';

String? _toNullableString(Object? raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

class VenueUpsertRequest {
  const VenueUpsertRequest({
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.fullRefundHours,
    required this.partialRefundHours,
    required this.partialRefundPct,
  });

  final String name;
  final String description;
  final VenueAddress address;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final int fullRefundHours;
  final int partialRefundHours;
  final int partialRefundPct;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'address': address.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'amenities': amenities
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      'full_refund_hours': fullRefundHours,
      'partial_refund_hours': partialRefundHours,
      'partial_refund_pct': partialRefundPct,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final payload = toJson();
    payload.removeWhere((key, value) => value == null);
    return payload;
  }
}

class VenueImageUploadRequest {
  const VenueImageUploadRequest({
    required this.uploadUrl,
    required this.method,
    required this.headers,
    this.publicUrl,
    this.imageUrl,
    this.key,
    this.confirmUrl,
  });

  final String uploadUrl;
  final String method;
  final Map<String, String> headers;
  final String? publicUrl;
  final String? imageUrl;
  final String? key;
  final String? confirmUrl;

  String? get resolvedImageUrl => imageUrl ?? publicUrl;

  factory VenueImageUploadRequest.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final parsedHeaders = <String, String>{};
    if (rawHeaders is Map<String, dynamic>) {
      for (final entry in rawHeaders.entries) {
        final key = entry.key.trim();
        final value = entry.value?.toString().trim();
        if (key.isNotEmpty && value != null && value.isNotEmpty) {
          parsedHeaders[key] = value;
        }
      }
    }

    return VenueImageUploadRequest(
      uploadUrl:
          (json['uploadUrl'] as String?) ?? (json['upload_url'] as String?) ?? '',
      method: ((json['method'] as String?) ?? 'PUT').toUpperCase(),
      headers: parsedHeaders,
      publicUrl:
        (json['publicUrl'] as String?) ??
        (json['public_url'] as String?) ??
        (json['cdnUrl'] as String?) ??
        (json['cdn_url'] as String?),
      imageUrl: (json['imageUrl'] as String?) ?? (json['image_url'] as String?),
      key: (json['key'] as String?) ?? (json['objectKey'] as String?),
      confirmUrl:
          (json['confirmUrl'] as String?) ?? (json['confirm_url'] as String?),
    );
  }
}
