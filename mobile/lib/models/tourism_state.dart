class TourismState {
  const TourismState({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory TourismState.fromJson(Map<String, dynamic> json) {
    return TourismState(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}
