import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attraction.dart';

class AttractionService {
  const AttractionService();

  Future<List<Attraction>> getAttractions({
    String search = '',
    String? state,
    String? category,
  }) async {
    final queryParameters = <String, String>{};

    final trimmedSearch = search.trim();

    if (trimmedSearch.isNotEmpty) {
      queryParameters['search'] = trimmedSearch;
    }

    if (state != null && state.trim().isNotEmpty) {
      queryParameters['state'] = state.trim();
    }

    if (category != null && category.trim().isNotEmpty) {
      queryParameters['category'] = category.trim();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/attractions').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw const FormatException('Invalid response received from server.');
    }

    if (response.statusCode != 200 || decodedBody['success'] != true) {
      throw Exception(
        decodedBody['message']?.toString() ?? 'Failed to load attractions.',
      );
    }

    final rawData = decodedBody['data'];

    if (rawData is! List) {
      throw const FormatException('Attraction data is not a list.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(Attraction.fromJson)
        .toList();
  }

  Future<Attraction> getAttractionById(int attractionId) async {
    if (attractionId <= 0) {
      throw ArgumentError.value(
        attractionId,
        'attractionId',
        'Attraction ID must be greater than zero.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/attractions/$attractionId');

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw const FormatException('Invalid response received from server.');
    }

    if (response.statusCode != 200 || decodedBody['success'] != true) {
      throw Exception(
        decodedBody['message']?.toString() ??
            'Failed to load attraction details.',
      );
    }

    final rawData = decodedBody['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('Invalid attraction data received.');
    }

    return Attraction.fromJson(rawData);
  }
}
