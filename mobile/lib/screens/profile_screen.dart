import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person_outline,
            size: 56,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Guest User',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Authentication will be added using Firebase.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Personal Information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About JelajahMY'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'JelajahMY',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'A Malaysian tourism companion application.',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature will be added soon.')),
    );
  }
}
