import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

class AttractionMapScreen extends StatelessWidget {
  const AttractionMapScreen({
    required this.attractionName,
    required this.latitude,
    required this.longitude,
    required this.address,
    super.key,
  });

  final String attractionName;
  final double latitude;
  final double longitude;
  final String address;

  LatLng get _location {
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attraction Map')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _location,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: ApiConfig.applicationPackageName,
                maxNativeZoom: 19,
                evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('OpenStreetMap tile error: $error');
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _location,
                    width: 80,
                    height: 80,
                    child: _AttractionMarker(attractionName: attractionName),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: _openOpenStreetMapCopyright,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 26,
            child: _LocationInformationCard(
              attractionName: attractionName,
              address: address,
              latitude: latitude,
              longitude: longitude,
              onOpenExternalMap: _openExternalMap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalMap() async {
    final uri = Uri(
      scheme: 'https',
      host: 'www.openstreetmap.org',
      path: '/',
      queryParameters: {
        'mlat': latitude.toString(),
        'mlon': longitude.toString(),
      },
      fragment: 'map=16/$latitude/$longitude',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      throw Exception('Unable to open the external map.');
    }
  }

  Future<void> _openOpenStreetMapCopyright() async {
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AttractionMarker extends StatelessWidget {
  const _AttractionMarker({required this.attractionName});

  final String attractionName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: attractionName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 3),
              boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Icon(
              Icons.location_on,
              color: colorScheme.onPrimary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationInformationCard extends StatelessWidget {
  const _LocationInformationCard({
    required this.attractionName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.onOpenExternalMap,
  });

  final String attractionName;
  final String address;
  final double latitude;
  final double longitude;
  final Future<void> Function() onOpenExternalMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attractionName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 19),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    address.trim().isEmpty ? 'Address not specified' : address,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Latitude: '
              '${latitude.toStringAsFixed(7)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Longitude: '
              '${longitude.toStringAsFixed(7)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await onOpenExternalMap();
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open external map.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in OpenStreetMap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
