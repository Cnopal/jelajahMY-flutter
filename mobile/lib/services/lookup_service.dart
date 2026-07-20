import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attraction_category.dart';
import '../models/tourism_state.dart';

class LookupService {
  const LookupService();

  Future<List<TourismState>> getStates() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/states');

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    final body = _decodeResponse(response);

    final rawData = body['data'];

    if (rawData is! List) {
      throw const FormatException('State data is not a list.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(TourismState.fromJson)
        .toList();
  }

  Future<List<AttractionCategory>> getCategories() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories');

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    final body = _decodeResponse(response);

    final rawData = body['data'];

    if (rawData is! List) {
      throw const FormatException('Category data is not a list.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(AttractionCategory.fromJson)
        .toList();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid response received from server.');
    }

    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Unable to retrieve data.',
      );
    }

    return decoded;
  }
}
