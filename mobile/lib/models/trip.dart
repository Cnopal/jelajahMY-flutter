class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
    this.items = const <TripItem>[],
  });

  final int id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  final List<TripItem> items;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return Trip(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      startDate: _toDate(json['start_date']),
      endDate: _toDate(json['end_date']),
      notes: _toNullableString(json['notes']),
      createdAt: _toNullableDateTime(json['created_at']),
      updatedAt: _toNullableDateTime(json['updated_at']),
      itemCount: _toInt(json['item_count']),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => TripItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <TripItem>[],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1970);
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _toNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class TripItem {
  const TripItem({
    required this.id,
    required this.attractionId,
    required this.attractionName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.stateName,
    required this.categoryName,
    required this.sequenceNumber,
    this.imageUrl,
    this.visitDate,
    this.visitTime,
    this.createdAt,
  });

  final int id;
  final int attractionId;
  final String attractionName;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String stateName;
  final String categoryName;
  final DateTime? visitDate;
  final String? visitTime;
  final int sequenceNumber;
  final DateTime? createdAt;

  factory TripItem.fromJson(Map<String, dynamic> json) {
    return TripItem(
      id: Trip._toInt(json['id']),
      attractionId: Trip._toInt(json['attraction_id']),
      attractionName: json['attraction_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      imageUrl: Trip._toNullableString(json['image_url']),
      stateName: json['state_name']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      visitDate: Trip._toNullableDateTime(json['visit_date']),
      visitTime: Trip._toNullableString(json['visit_time']),
      sequenceNumber: Trip._toInt(json['sequence_number']),
      createdAt: Trip._toNullableDateTime(json['created_at']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ItineraryUpdate {
  const ItineraryUpdate({
    required this.itemId,
    required this.sequenceNumber,
    this.visitDate,
    this.visitTime,
  });

  final int itemId;
  final DateTime? visitDate;
  final String? visitTime;
  final int sequenceNumber;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'visitDate': visitDate == null ? null : formatApiDate(visitDate!),
      'visitTime': visitTime,
      'sequenceNumber': sequenceNumber,
    };
  }
}

String formatApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
