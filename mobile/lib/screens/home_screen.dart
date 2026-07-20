import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onExplorePressed, super.key});

  final VoidCallback onExplorePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.travel_explore,
                size: 52,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(height: 18),
              Text(
                'Discover Malaysia',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore destinations, historical landmarks, '
                'natural attractions and cultural experiences '
                'throughout Malaysia.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onExplorePressed,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explore Attractions'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Quick Access',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.map_outlined,
                title: 'Map',
                subtitle: 'Coming soon',
                onTap: () {
                  _showComingSoon(context, 'Interactive map');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.cloud_outlined,
                title: 'Weather',
                subtitle: 'Coming soon',
                onTap: () {
                  _showComingSoon(context, 'Weather forecast');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Explore JelajahMY',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const _FeatureTile(
          icon: Icons.location_on_outlined,
          title: 'Malaysian Destinations',
          subtitle: 'Discover attractions from different Malaysian states.',
        ),
        const SizedBox(height: 10),
        const _FeatureTile(
          icon: Icons.category_outlined,
          title: 'Multiple Categories',
          subtitle:
              'Explore historical, natural, cultural and family attractions.',
        ),
        const SizedBox(height: 10),
        const _FeatureTile(
          icon: Icons.bookmark_outline,
          title: 'Save Your Favourites',
          subtitle: 'Bookmark interesting destinations for future trips.',
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature will be added soon.')));
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
      ),
    );
  }
}
