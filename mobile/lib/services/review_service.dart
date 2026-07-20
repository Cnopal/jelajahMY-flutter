import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/review.dart';

class ReviewService {
  ReviewService({FirebaseAuth? firebaseAuth, http.Client? httpClient})
    : _firebaseAuthProvider = (firebaseAuth == null
          ? _defaultFirebaseAuth
          : () => firebaseAuth),
      _httpClient = httpClient ?? http.Client();

  final FirebaseAuth Function() _firebaseAuthProvider;
  final http.Client _httpClient;

  static FirebaseAuth _defaultFirebaseAuth() => FirebaseAuth.instance;

  Future<List<Review>> getReviews(int attractionId) async {
    final response = await _httpClient
        .get(_uri(attractionId), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
    final data = payload['data'];

    if (data is! List) {
      throw const ReviewException('The backend returned invalid review data.');
    }

    return data
        .whereType<Map>()
        .map((item) => Review.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<RatingSummary> getRatingSummary(int attractionId) async {
    final response = await _httpClient
        .get(
          _uri(attractionId, '/summary'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
    final data = payload['data'];

    if (data is! Map) {
      throw const ReviewException(
        'The backend returned an invalid rating summary.',
      );
    }

    return RatingSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Review?> getCurrentUserReview(int attractionId) async {
    final response = await _httpClient
        .get(_uri(attractionId, '/me'), headers: await _authorizedHeaders())
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
    final data = payload['data'];

    if (data == null) return null;
    if (data is! Map) {
      throw const ReviewException('The backend returned invalid review data.');
    }
    return Review.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Review> createReview({
    required int attractionId,
    required int rating,
    String? comment,
  }) async {
    final response = await _httpClient
        .post(
          _uri(attractionId),
          headers: await _authorizedHeaders(includeJson: true),
          body: jsonEncode({'rating': rating, 'comment': comment?.trim()}),
        )
        .timeout(const Duration(seconds: 20));
    return _reviewFromMutation(response, const {201});
  }

  Future<Review> updateReview({
    required int attractionId,
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    final response = await _httpClient
        .put(
          _uri(attractionId, '/$reviewId'),
          headers: await _authorizedHeaders(includeJson: true),
          body: jsonEncode({'rating': rating, 'comment': comment?.trim()}),
        )
        .timeout(const Duration(seconds: 20));
    return _reviewFromMutation(response, const {200});
  }

  Future<void> deleteReview({
    required int attractionId,
    required int reviewId,
  }) async {
    final response = await _httpClient
        .delete(
          _uri(attractionId, '/$reviewId'),
          headers: await _authorizedHeaders(),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
  }

  Uri _uri(int attractionId, [String suffix = '']) {
    return Uri.parse(
      '${ApiConfig.baseUrl}/api/attractions/$attractionId/reviews$suffix',
    );
  }

  Future<Map<String, String>> _authorizedHeaders({
    bool includeJson = false,
  }) async {
    final user = _firebaseAuthProvider().currentUser;

    if (user == null) {
      throw const ReviewException('No authenticated user was found.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw const ReviewException('Unable to obtain the Firebase ID token.');
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (includeJson) 'Content-Type': 'application/json',
    };
  }

  Review _reviewFromMutation(
    http.Response response,
    Set<int> expectedStatuses,
  ) {
    final payload = _decode(response);
    _requireStatus(response, payload, expectedStatuses);
    final data = payload['data'];

    if (data is! Map) {
      throw const ReviewException('The backend returned invalid review data.');
    }

    return Review.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw const ReviewException('The backend returned an empty response.');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Converted to a domain exception below.
    }

    throw const ReviewException('The backend returned an invalid response.');
  }

  void _requireStatus(
    http.Response response,
    Map<String, dynamic> payload,
    Set<int> expectedStatuses,
  ) {
    if (!expectedStatuses.contains(response.statusCode) ||
        payload['success'] != true) {
      throw ReviewException(
        payload['message']?.toString() ?? 'Unable to complete the request.',
      );
    }
  }
}

class ReviewException implements Exception {
  const ReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}
