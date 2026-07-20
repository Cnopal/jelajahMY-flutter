import 'package:flutter/material.dart';

import '../models/weather_forecast.dart';
import '../services/weather_service.dart';

class WeatherSection extends StatefulWidget {
  const WeatherSection({
    required this.latitude,
    required this.longitude,
    super.key,
  });

  final double latitude;
  final double longitude;

  @override
  State<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<WeatherSection> {
  final WeatherService _weatherService = const WeatherService();

  late Future<WeatherForecast> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather() {
    _weatherFuture = _weatherService.getWeather(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
  }

  void _retry() {
    setState(_loadWeather);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherForecast>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WeatherLoadingCard();
        }

        if (snapshot.hasError) {
          return _WeatherErrorCard(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final forecast = snapshot.data;

        if (forecast == null) {
          return _WeatherErrorCard(
            message: 'Weather data is unavailable.',
            onRetry: _retry,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentWeatherCard(
              weather: forecast.current,
              timezone: forecast.timezone,
            ),
            const SizedBox(height: 12),
            _DailyForecastCard(forecasts: forecast.daily),
          ],
        );
      },
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({required this.weather, required this.timezone});

  final CurrentWeather weather;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final condition = _WeatherCondition.fromCode(
      weather.weatherCode,
      isDay: weather.isDay,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    condition.icon,
                    size: 42,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(condition.label, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Feels like '
                        '${weather.apparentTemperature.toStringAsFixed(1)}°C',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _WeatherMetric(
                  icon: Icons.water_drop_outlined,
                  title: 'Humidity',
                  value: '${weather.relativeHumidity}%',
                ),
                _WeatherMetric(
                  icon: Icons.air,
                  title: 'Wind',
                  value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                ),
                _WeatherMetric(
                  icon: weather.isDay
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  title: 'Period',
                  value: weather.isDay ? 'Day' : 'Night',
                ),
              ],
            ),
            if (timezone.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Timezone: $timezone', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyForecastCard extends StatelessWidget {
  const _DailyForecastCard({required this.forecasts});

  final List<DailyWeather> forecasts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3-Day Forecast',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < forecasts.length; index++) ...[
              _DailyForecastRow(forecast: forecasts[index]),
              if (index != forecasts.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyForecastRow extends StatelessWidget {
  const _DailyForecastRow({required this.forecast});

  final DailyWeather forecast;

  @override
  Widget build(BuildContext context) {
    final condition = _WeatherCondition.fromCode(
      forecast.weatherCode,
      isDay: true,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              _formatDate(forecast.date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(condition.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              condition.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.water_drop_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Text('${forecast.precipitationProbability}%'),
          const SizedBox(width: 12),
          Text(
            '${forecast.maximumTemperature.toStringAsFixed(0)}°'
            ' / '
            '${forecast.minimumTemperature.toStringAsFixed(0)}°',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (_isToday(date)) {
      return 'Today';
    }

    return weekdays[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();

    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}

class _WeatherMetric extends StatelessWidget {
  const _WeatherMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 125),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Loading weather forecast...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherErrorCard extends StatelessWidget {
  const _WeatherErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Unable to load weather',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCondition {
  const _WeatherCondition({required this.label, required this.icon});

  final String label;
  final IconData icon;

  factory _WeatherCondition.fromCode(int code, {required bool isDay}) {
    if (code == 0) {
      return _WeatherCondition(
        label: 'Clear sky',
        icon: isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
      );
    }

    if (code == 1 || code == 2) {
      return const _WeatherCondition(
        label: 'Partly cloudy',
        icon: Icons.cloud_queue,
      );
    }

    if (code == 3) {
      return const _WeatherCondition(label: 'Overcast', icon: Icons.cloud);
    }

    if (code == 45 || code == 48) {
      return const _WeatherCondition(label: 'Foggy', icon: Icons.foggy);
    }

    if (code >= 51 && code <= 57) {
      return const _WeatherCondition(label: 'Drizzle', icon: Icons.grain);
    }

    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      return const _WeatherCondition(
        label: 'Rain',
        icon: Icons.umbrella_outlined,
      );
    }

    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return const _WeatherCondition(label: 'Snow', icon: Icons.ac_unit);
    }

    if (code >= 95 && code <= 99) {
      return const _WeatherCondition(
        label: 'Thunderstorm',
        icon: Icons.thunderstorm_outlined,
      );
    }

    return const _WeatherCondition(
      label: 'Unknown condition',
      icon: Icons.cloud_outlined,
    );
  }
}
