import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attraction.dart';

class AttractionService {
  const AttractionService();

  Future<List<Attraction>> getAttractions() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/attractions');

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load attractions. '
        'Status code: ${response.statusCode}',
      );
    }

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw const FormatException('Invalid response received from server.');
    }

    if (decodedBody['success'] != true) {
      throw Exception(
        decodedBody['message']?.toString() ?? 'The server returned an error.',
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
}
