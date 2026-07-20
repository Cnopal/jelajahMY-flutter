import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';

class BackendUserService {
  BackendUserService({FirebaseAuth? firebaseAuth, http.Client? httpClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _httpClient = httpClient ?? http.Client();

  final FirebaseAuth _firebaseAuth;
  final http.Client _httpClient;

  Future<AppUser> syncCurrentUser({String? name}) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const BackendUserException(
        'No authenticated Firebase user was found.',
      );
    }

    final idToken = await _getIdToken(user);

    final requestBody = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) {
      requestBody['name'] = name.trim();
    }

    final response = await _httpClient
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/sync'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 20));

    final payload = _decodeResponse(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw BackendUserException(
        payload['message']?.toString() ?? 'Unable to synchronise the user.',
      );
    }

    final data = payload['data'];

    if (data is! Map) {
      throw const BackendUserException(
        'The backend returned invalid user data.',
      );
    }

    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<AppUser> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const BackendUserException(
        'No authenticated Firebase user was found.',
      );
    }

    final idToken = await _getIdToken(user);

    final response = await _httpClient
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        )
        .timeout(const Duration(seconds: 20));

    final payload = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw BackendUserException(
        payload['message']?.toString() ??
            'Unable to retrieve the user profile.',
      );
    }

    final data = payload['data'];

    if (data is! Map) {
      throw const BackendUserException(
        'The backend returned invalid user data.',
      );
    }

    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<String> _getIdToken(User user) async {
    final tokenResult = await user.getIdTokenResult();
    final idToken = tokenResult.token;

    if (idToken == null || idToken.isEmpty) {
      throw const BackendUserException(
        'Unable to obtain the Firebase ID token.',
      );
    }

    return idToken;
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

    throw const BackendUserException(
      'The backend returned an invalid response.',
    );
  }
}

class BackendUserException implements Exception {
  const BackendUserException(this.message);

  final String message;

  @override
  String toString() => message;
}
