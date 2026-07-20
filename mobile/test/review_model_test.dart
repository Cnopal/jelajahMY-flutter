import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/review.dart';

void main() {
  test('Review parses the backend review response', () {
    final review = Review.fromJson({
      'id': 14,
      'rating': 5,
      'comment': 'A wonderful place to visit.',
      'image_url': null,
      'created_at': '2026-07-21T10:00:00.000Z',
      'updated_at': '2026-07-21T11:00:00.000Z',
      'reviewer_name': 'Aisyah',
      'reviewer_profile_image_url': 'https://example.com/profile.jpg',
    });

    expect(review.id, 14);
    expect(review.rating, 5);
    expect(review.comment, 'A wonderful place to visit.');
    expect(review.imageUrl, isNull);
    expect(review.reviewerName, 'Aisyah');
    expect(review.reviewerProfileImageUrl, isNotNull);
    expect(review.wasUpdated, isTrue);
  });

  test('RatingSummary parses numeric backend values', () {
    final summary = RatingSummary.fromJson({
      'attraction_id': 3,
      'average_rating': 4.25,
      'total_reviews': '8',
    });

    expect(summary.attractionId, 3);
    expect(summary.averageRating, 4.25);
    expect(summary.totalReviews, 8);
  });
}
