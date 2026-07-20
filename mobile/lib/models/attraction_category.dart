class AttractionCategory {
  const AttractionCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory AttractionCategory.fromJson(Map<String, dynamic> json) {
    return AttractionCategory(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
