import 'package:flutter_test/flutter_test.dart';

import 'package:futsmandu/features/venues/domain/models/court_models.dart';
import 'package:futsmandu/features/venues/domain/models/venue_models.dart';

void main() {
  test('VenueUpsertRequest serializes fixed venue payload', () {
    final request = VenueUpsertRequest(
      name: 'Arena One',
      description: 'Main venue',
      address: const VenueAddress(
        street: 'Street 1',
        city: 'Kathmandu',
        district: 'Kathmandu',
      ),
      latitude: 27.7172,
      longitude: 85.324,
      amenities: const ['Parking', 'WiFi'],
      fullRefundHours: 24,
      partialRefundHours: 12,
      partialRefundPct: 50,
    );

    expect(request.toJson(), {
      'name': 'Arena One',
      'description': 'Main venue',
      'address': {
        'street': 'Street 1',
        'city': 'Kathmandu',
        'district': 'Kathmandu',
      },
      'latitude': 27.7172,
      'longitude': 85.324,
      'amenities': ['Parking', 'WiFi'],
      'full_refund_hours': 24,
      'partial_refund_hours': 12,
      'partial_refund_pct': 50,
    });
  });

  test('CourtUpsertRequest serializes fixed court payload', () {
    final request = CourtUpsertRequest(
      name: 'Court A',
      courtType: 'Indoor',
      surface: 'Artificial Turf',
      capacity: 12,
      minPlayers: 4,
      slotDurationMins: 60,
      openTime: '06:00',
      closeTime: '22:00',
    );

    expect(request.toJson(), {
      'name': 'Court A',
      'court_type': 'Indoor',
      'surface': 'Artificial Turf',
      'capacity': 12,
      'min_players': 4,
      'slot_duration_mins': 60,
      'open_time': '06:00',
      'close_time': '22:00',
    });
  });

  test('Venue and Court models parse fixed API responses', () {
    final venue = Venue.fromJson({
      'id': 'venue-1',
      'name': 'Arena One',
      'description': 'Main venue',
      'address': {
        'street': 'Street 1',
        'city': 'Kathmandu',
        'district': 'Kathmandu',
      },
      'latitude': 27.7172,
      'longitude': 85.324,
      'amenities': ['Parking', 'WiFi'],
      'full_refund_hours': 24,
      'partial_refund_hours': 12,
      'partial_refund_pct': 50,
      'image_url': 'https://example.com/image.jpg',
      'is_active': true,
    });

    final court = Court.fromJson({
      'id': 'court-1',
      'venue_id': 'venue-1',
      'name': 'Court A',
      'court_type': 'Indoor',
      'surface': 'Artificial Turf',
      'capacity': 12,
      'min_players': 4,
      'slot_duration_mins': 60,
      'open_time': '06:00',
      'close_time': '22:00',
      'is_active': true,
    });

    expect(venue.displayAddress, 'Street 1, Kathmandu, Kathmandu');
    expect(court.summary, 'Artificial Turf • Capacity 12');
    expect(court.venueId, 'venue-1');
  });

  test('Venue model tolerates mixed backend value types', () {
    final venue = Venue.fromJson({
      'id': 123,
      'name': 'Arena Two',
      'description': null,
      'address': {
        'street': 'Street 2',
        'city': 'Pokhara',
        'district': 10,
      },
      'latitude': '27.7',
      'longitude': 85,
      'amenities': ['Parking', 200, null],
      'full_refund_hours': '24',
      'partial_refund_hours': 6.0,
      'partial_refund_pct': '50',
      'cover_image_url': '',
      'is_verified': 'true',
      'is_active': 1,
      '_count': {'courts': '3'},
    });

    expect(venue.id, '123');
    expect(venue.description, '');
    expect(venue.address.formatted, 'Street 2, Pokhara, 10');
    expect(venue.latitude, 27.7);
    expect(venue.longitude, 85.0);
    expect(venue.amenities, ['Parking', '200']);
    expect(venue.fullRefundHours, 24);
    expect(venue.partialRefundHours, 6);
    expect(venue.partialRefundPct, 50);
    expect(venue.imageUrl, isNull);
    expect(venue.isVerified, isTrue);
    expect(venue.isActive, isTrue);
    expect(venue.courtsCount, 3);
  });
}
