import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attraction.dart';

class BookmarkService {
  BookmarkService({FirebaseAuth? firebaseAuth, http.Client? httpClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _httpClient = httpClient ?? http.Client();

  final FirebaseAuth _firebaseAuth;
  final http.Client _httpClient;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<Attraction>> getBookmarks() async {
    final headers = await _authorizedHeaders();

    final response = await _httpClient
        .get(Uri.parse('${ApiConfig.baseUrl}/api/bookmarks'), headers: headers)
        .timeout(const Duration(seconds: 20));

    final payload = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw BookmarkException(
        payload['message']?.toString() ?? 'Unable to retrieve bookmarks.',
      );
    }

    final data = payload['data'];

    if (data is! List) {
      throw const BookmarkException(
        'The backend returned invalid bookmark data.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => Attraction.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<bool> getBookmarkStatus({required int attractionId}) async {
    final headers = await _authorizedHeaders();

    final response = await _httpClient
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}'
            '/api/bookmarks/status/$attractionId',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));

    final payload = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw BookmarkException(
        payload['message']?.toString() ?? 'Unable to check bookmark status.',
      );
    }

    final data = payload['data'];

    if (data is! Map) {
      throw const BookmarkException(
        'The backend returned invalid bookmark status.',
      );
    }

    return data['is_bookmarked'] == true || data['is_bookmarked'] == 1;
  }

  Future<void> addBookmark({required int attractionId}) async {
    final headers = await _authorizedHeaders();

    final response = await _httpClient
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}'
            '/api/bookmarks/$attractionId',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));

    final payload = _decodeResponse(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw BookmarkException(
        payload['message']?.toString() ?? 'Unable to add the bookmark.',
      );
    }

    _notifyBookmarkChanges();
  }

  Future<void> removeBookmark({required int attractionId}) async {
    final headers = await _authorizedHeaders();

    final response = await _httpClient
        .delete(
          Uri.parse(
            '${ApiConfig.baseUrl}'
            '/api/bookmarks/$attractionId',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));

    final payload = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw BookmarkException(
        payload['message']?.toString() ?? 'Unable to remove the bookmark.',
      );
    }

    _notifyBookmarkChanges();
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const BookmarkException('No authenticated user was found.');
    }

    final tokenResult = await user.getIdTokenResult();

    final idToken = tokenResult.token;

    if (idToken == null || idToken.isEmpty) {
      throw const BookmarkException('Unable to obtain the Firebase ID token.');
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $idToken'};
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // Handled below.
    }

    throw const BookmarkException('The backend returned an invalid response.');
  }

  void _notifyBookmarkChanges() {
    changes.value++;
  }
}

class BookmarkException implements Exception {
  const BookmarkException(this.message);

  final String message;

  @override
  String toString() => message;
}
