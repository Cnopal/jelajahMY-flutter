import 'package:flutter/material.dart';

import '../models/attraction.dart';
import '../services/attraction_service.dart';

class AttractionDetailScreen extends StatefulWidget {
  const AttractionDetailScreen({required this.attractionId, super.key});

  final int attractionId;

  @override
  State<AttractionDetailScreen> createState() => _AttractionDetailScreenState();
}

class _AttractionDetailScreenState extends State<AttractionDetailScreen> {
  final AttractionService _attractionService = const AttractionService();

  late Future<Attraction> _attractionFuture;

  @override
  void initState() {
    super.initState();
    _loadAttraction();
  }

  void _loadAttraction() {
    _attractionFuture = _attractionService.getAttractionById(
      widget.attractionId,
    );
  }

  void _retry() {
    setState(_loadAttraction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attraction Details')),
      body: FutureBuilder<Attraction>(
        future: _attractionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailErrorView(
              message: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          final attraction = snapshot.data;

          if (attraction == null) {
            return const Center(
              child: Text('Attraction details are unavailable.'),
            );
          }

          return _AttractionDetailContent(attraction: attraction);
        },
      ),
    );
  }
}

class _AttractionDetailContent extends StatelessWidget {
  const _AttractionDetailContent({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttractionHeader(attraction: attraction),
          const SizedBox(height: 24),
          Text(
            'About',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            attraction.description.isEmpty
                ? 'No description is available.'
                : attraction.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Visitor Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InformationCard(
            children: [
              _InformationRow(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: attraction.address.isEmpty
                    ? 'Not specified'
                    : attraction.address,
              ),
              const Divider(height: 28),
              _InformationRow(
                icon: Icons.schedule_outlined,
                title: 'Opening Hours',
                value: attraction.openingHours.isEmpty
                    ? 'Not specified'
                    : attraction.openingHours,
              ),
              const Divider(height: 28),
              _InformationRow(
                icon: Icons.payments_outlined,
                title: 'Entrance Fee',
                value: _formatEntranceFee(attraction.entranceFee),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Location Coordinates',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InformationCard(
            children: [
              _InformationRow(
                icon: Icons.explore_outlined,
                title: 'Latitude',
                value: attraction.latitude.toStringAsFixed(7),
              ),
              const Divider(height: 28),
              _InformationRow(
                icon: Icons.public_outlined,
                title: 'Longitude',
                value: attraction.longitude.toStringAsFixed(7),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Map Coming Soon'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('Weather Coming Soon'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEntranceFee(double fee) {
    if (fee <= 0) {
      return 'Not specified';
    }

    return 'RM ${fee.toStringAsFixed(2)}';
  }
}

class _AttractionHeader extends StatelessWidget {
  const _AttractionHeader({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 210,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: attraction.imageUrl == null
              ? Icon(
                  Icons.landscape_outlined,
                  size: 80,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    attraction.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.broken_image_outlined,
                        size: 80,
                        color: theme.colorScheme.onPrimaryContainer,
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 20),
        Text(
          attraction.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.location_city_outlined, size: 18),
              label: Text(attraction.stateName),
            ),
            Chip(
              avatar: const Icon(Icons.category_outlined, size: 18),
              label: Text(attraction.categoryName),
            ),
          ],
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Unable to load attraction details',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
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
