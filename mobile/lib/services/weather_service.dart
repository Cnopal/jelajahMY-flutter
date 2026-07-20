import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/weather_forecast.dart';

class WeatherService {
  const WeatherService();

  Future<WeatherForecast> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Latitude must be between -90 and 90.',
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Longitude must be between -180 and 180.',
      );
    }

    final uri = Uri.parse('${ApiConfig.openMeteoBaseUrl}/v1/forecast').replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(7),
        'longitude': longitude.toStringAsFixed(7),
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'is_day',
          'weather_code',
          'wind_speed_10m',
        ].join(','),
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_probability_max',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': '3',
      },
    );

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'Invalid response received from weather service.',
      );
    }

    if (response.statusCode != 200) {
      String message = 'Unable to retrieve weather data.';

      if (decodedBody is Map) {
        message =
            decodedBody['reason']?.toString() ??
            decodedBody['message']?.toString() ??
            message;
      }

      throw Exception(message);
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw const FormatException('Invalid weather data received.');
    }

    return WeatherForecast.fromJson(decodedBody);
  }
}
