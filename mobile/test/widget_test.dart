import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/trip.dart';

void main() {
  test('Trip parses the backend list response structure', () {
    final trip = Trip.fromJson({
      'id': 7,
      'title': 'Melaka Weekend',
      'start_date': '2026-08-10',
      'end_date': '2026-08-12',
      'notes': 'Heritage trip',
      'item_count': '2',
      'created_at': '2026-07-21T10:00:00.000Z',
      'updated_at': '2026-07-21T10:00:00.000Z',
    });

    expect(trip.id, 7);
    expect(trip.title, 'Melaka Weekend');
    expect(formatApiDate(trip.startDate), '2026-08-10');
    expect(formatApiDate(trip.endDate), '2026-08-12');
    expect(trip.itemCount, 2);
    expect(trip.items, isEmpty);
  });

  test('Trip parses itinerary items from the detail response', () {
    final trip = Trip.fromJson({
      'id': 7,
      'title': 'Melaka Weekend',
      'start_date': '2026-08-10',
      'end_date': '2026-08-12',
      'items': [
        {
          'id': 12,
          'attraction_id': 3,
          'attraction_name': 'A Famosa',
          'address': 'Bandar Hilir, Melaka',
          'latitude': '2.1919000',
          'longitude': '102.2505000',
          'image_url': null,
          'state_name': 'Melaka',
          'category_name': 'Historical',
          'visit_date': '2026-08-10',
          'visit_time': '09:30:00',
          'sequence_number': 1,
          'created_at': '2026-07-21T10:00:00.000Z',
        },
      ],
    });

    expect(trip.items, hasLength(1));
    expect(trip.items.single.attractionName, 'A Famosa');
    expect(trip.items.single.stateName, 'Melaka');
    expect(formatApiDate(trip.items.single.visitDate!), '2026-08-10');
    expect(trip.items.single.sequenceNumber, 1);
  });
}
