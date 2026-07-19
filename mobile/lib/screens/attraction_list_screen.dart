import 'package:flutter/material.dart';

import '../models/attraction.dart';
import '../services/attraction_service.dart';

class AttractionListScreen extends StatefulWidget {
  const AttractionListScreen({super.key});

  @override
  State<AttractionListScreen> createState() => _AttractionListScreenState();
}

class _AttractionListScreenState extends State<AttractionListScreen> {
  final AttractionService _attractionService = const AttractionService();

  late Future<List<Attraction>> _attractionsFuture;

  @override
  void initState() {
    super.initState();
    _loadAttractions();
  }

  void _loadAttractions() {
    _attractionsFuture = _attractionService.getAttractions();
  }

  Future<void> _refreshAttractions() async {
    setState(_loadAttractions);
    await _attractionsFuture;
  }

  void _retry() {
    setState(_loadAttractions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JelajahMY'), centerTitle: true),
      body: FutureBuilder<List<Attraction>>(
        future: _attractionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          final attractions = snapshot.data ?? const <Attraction>[];

          if (attractions.isEmpty) {
            return const Center(child: Text('No attractions found.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshAttractions,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: attractions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final attraction = attractions[index];

                return _AttractionCard(attraction: attraction);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AttractionCard extends StatelessWidget {
  const _AttractionCard({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${attraction.name} selected')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.landscape_outlined, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      attraction.stateName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attraction.categoryName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attraction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            const Icon(Icons.cloud_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Unable to load attractions',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
