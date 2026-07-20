class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.reviewerName,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    this.imageUrl,
    this.reviewerProfileImageUrl,
  });

  final int id;
  final int rating;
  final String? comment;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reviewerName;
  final String? reviewerProfileImageUrl;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: _toInt(json['id']),
      rating: _toInt(json['rating']),
      comment: _toNullableString(json['comment']),
      imageUrl: _toNullableString(json['image_url']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      reviewerName: json['reviewer_name']?.toString().trim().isNotEmpty == true
          ? json['reviewer_name'].toString().trim()
          : 'JelajahMY User',
      reviewerProfileImageUrl: _toNullableString(
        json['reviewer_profile_image_url'],
      ),
    );
  }

  bool get wasUpdated =>
      updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1970);
  }

  static String? _toNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class RatingSummary {
  const RatingSummary({
    required this.attractionId,
    required this.averageRating,
    required this.totalReviews,
  });

  final int attractionId;
  final double averageRating;
  final int totalReviews;

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      attractionId: Review._toInt(json['attraction_id']),
      averageRating: _toDouble(json['average_rating']),
      totalReviews: Review._toInt(json['total_reviews']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
