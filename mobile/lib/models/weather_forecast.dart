class WeatherForecast {
  const WeatherForecast({
    required this.current,
    required this.daily,
    required this.timezone,
  });

  final CurrentWeather current;
  final List<DailyWeather> daily;
  final String timezone;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final currentJson = _toMap(json['current'], 'current');

    final dailyJson = _toMap(json['daily'], 'daily');

    final dates = _toList(dailyJson['time'], 'daily.time');

    final weatherCodes = _toList(
      dailyJson['weather_code'],
      'daily.weather_code',
    );

    final maximumTemperatures = _toList(
      dailyJson['temperature_2m_max'],
      'daily.temperature_2m_max',
    );

    final minimumTemperatures = _toList(
      dailyJson['temperature_2m_min'],
      'daily.temperature_2m_min',
    );

    final precipitationProbabilities = _toList(
      dailyJson['precipitation_probability_max'],
      'daily.precipitation_probability_max',
    );

    final lengths = <int>[
      dates.length,
      weatherCodes.length,
      maximumTemperatures.length,
      minimumTemperatures.length,
      precipitationProbabilities.length,
    ];

    final forecastLength = lengths.reduce((currentLength, nextLength) {
      return currentLength < nextLength ? currentLength : nextLength;
    });

    final dailyForecast = List<DailyWeather>.generate(forecastLength, (index) {
      return DailyWeather(
        date: DateTime.parse(dates[index].toString()),
        weatherCode: _toInt(weatherCodes[index]),
        maximumTemperature: _toDouble(maximumTemperatures[index]),
        minimumTemperature: _toDouble(minimumTemperatures[index]),
        precipitationProbability: _toInt(precipitationProbabilities[index]),
      );
    });

    return WeatherForecast(
      current: CurrentWeather(
        time: currentJson['time']?.toString() ?? '',
        temperature: _toDouble(currentJson['temperature_2m']),
        apparentTemperature: _toDouble(currentJson['apparent_temperature']),
        relativeHumidity: _toInt(currentJson['relative_humidity_2m']),
        weatherCode: _toInt(currentJson['weather_code']),
        windSpeed: _toDouble(currentJson['wind_speed_10m']),
        isDay: _toInt(currentJson['is_day']) == 1,
      ),
      daily: dailyForecast,
      timezone: json['timezone']?.toString() ?? '',
    );
  }
}

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.relativeHumidity,
    required this.weatherCode,
    required this.windSpeed,
    required this.isDay,
  });

  final String time;
  final double temperature;
  final double apparentTemperature;
  final int relativeHumidity;
  final int weatherCode;
  final double windSpeed;
  final bool isDay;
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.maximumTemperature,
    required this.minimumTemperature,
    required this.precipitationProbability,
  });

  final DateTime date;
  final int weatherCode;
  final double maximumTemperature;
  final double minimumTemperature;
  final int precipitationProbability;
}

Map<String, dynamic> _toMap(dynamic value, String fieldName) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw FormatException('Invalid or missing $fieldName data.');
}

List<dynamic> _toList(dynamic value, String fieldName) {
  if (value is List) {
    return List<dynamic>.from(value);
  }

  throw FormatException('Invalid or missing $fieldName data.');
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
