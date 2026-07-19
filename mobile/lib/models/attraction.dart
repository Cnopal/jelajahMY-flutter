class Attraction {
  const Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.entranceFee,
    required this.stateId,
    required this.stateName,
    required this.stateCode,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String openingHours;
  final double entranceFee;
  final String? imageUrl;

  final int stateId;
  final String stateName;
  final String stateCode;

  final int categoryId;
  final String categoryName;

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      openingHours: json['openingHours']?.toString() ?? '',
      entranceFee: _toDouble(json['entranceFee']),
      imageUrl: _toNullableString(json['imageUrl']),
      stateId: _toInt(json['stateId']),
      stateName: json['stateName']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',
      categoryId: _toInt(json['categoryId']),
      categoryName: json['categoryName']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
