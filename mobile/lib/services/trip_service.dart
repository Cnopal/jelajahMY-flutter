import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/trip.dart';

class TripService {
  TripService({FirebaseAuth? firebaseAuth, http.Client? httpClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _httpClient = httpClient ?? http.Client();

  final FirebaseAuth _firebaseAuth;
  final http.Client _httpClient;

  Future<List<Trip>> getTrips() async {
    final response = await _httpClient
        .get(_uri('/api/trips'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
    final data = payload['data'];

    if (data is! List) {
      throw const TripException('The backend returned invalid trip data.');
    }

    return data
        .whereType<Map>()
        .map((item) => Trip.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Trip> getTrip(int tripId) async {
    final response = await _httpClient
        .get(_uri('/api/trips/$tripId'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
    return _tripFromPayload(payload);
  }

  Future<Trip> createTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final response = await _httpClient
        .post(
          _uri('/api/trips'),
          headers: await _headers(includeJson: true),
          body: jsonEncode(_tripBody(title, startDate, endDate, notes)),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {201});
    return _tripFromPayload(payload);
  }

  Future<Trip> updateTrip({
    required int tripId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final response = await _httpClient
        .put(
          _uri('/api/trips/$tripId'),
          headers: await _headers(includeJson: true),
          body: jsonEncode(_tripBody(title, startDate, endDate, notes)),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
    return _tripFromPayload(payload);
  }

  Future<void> deleteTrip(int tripId) async {
    final response = await _httpClient
        .delete(_uri('/api/trips/$tripId'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
  }

  Future<void> addAttraction({
    required int tripId,
    required int attractionId,
  }) async {
    final response = await _httpClient
        .post(
          _uri('/api/trips/$tripId/items'),
          headers: await _headers(includeJson: true),
          body: jsonEncode({'attractionId': attractionId}),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {201});
  }

  Future<void> removeAttraction({
    required int tripId,
    required int itemId,
  }) async {
    final response = await _httpClient
        .delete(
          _uri('/api/trips/$tripId/items/$itemId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
  }

  Future<void> updateItinerary({
    required int tripId,
    required List<ItineraryUpdate> items,
  }) async {
    final response = await _httpClient
        .put(
          _uri('/api/trips/$tripId/itinerary'),
          headers: await _headers(includeJson: true),
          body: jsonEncode({
            'items': items.map((item) => item.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    _requireStatus(response, payload, const {200});
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, dynamic> _tripBody(
    String title,
    DateTime startDate,
    DateTime endDate,
    String? notes,
  ) {
    return {
      'title': title.trim(),
      'startDate': formatApiDate(startDate),
      'endDate': formatApiDate(endDate),
      'notes': notes?.trim(),
    };
  }

  Future<Map<String, String>> _headers({bool includeJson = false}) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const TripException('No authenticated user was found.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw const TripException('Unable to obtain the Firebase ID token.');
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (includeJson) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Converted to a domain exception below.
    }

    throw const TripException('The backend returned an invalid response.');
  }

  void _requireStatus(
    http.Response response,
    Map<String, dynamic> payload,
    Set<int> expectedStatuses,
  ) {
    if (!expectedStatuses.contains(response.statusCode) ||
        payload['success'] != true) {
      throw TripException(
        payload['message']?.toString() ?? 'Unable to complete the request.',
      );
    }
  }

  Trip _tripFromPayload(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! Map) {
      throw const TripException('The backend returned invalid trip data.');
    }
    return Trip.fromJson(Map<String, dynamic>.from(data));
  }
}

class TripException implements Exception {
  const TripException(this.message);

  final String message;

  @override
  String toString() => message;
}
