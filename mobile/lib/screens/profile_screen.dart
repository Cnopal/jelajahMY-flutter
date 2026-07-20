import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  bool _isSigningOut = false;

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out '
            'from JelajahMY?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(error))));

      setState(() {
        _isSigningOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'JelajahMY User';

    final email = user?.email ?? 'Email unavailable';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _getInitial(displayName),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Firebase User ID'),
                    subtitle: Text(
                      user?.uid ?? 'Unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      user?.emailVerified == true
                          ? Icons.verified_outlined
                          : Icons.warning_amber_outlined,
                    ),
                    title: const Text('Email Status'),
                    subtitle: Text(
                      user?.emailVerified == true ? 'Verified' : 'Not verified',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.login_outlined),
                    title: const Text('Last Sign In'),
                    subtitle: Text(
                      _formatDateTime(user?.metadata.lastSignInTime),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isSigningOut ? null : _confirmSignOut,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isSigningOut ? 'Signing Out...' : 'Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitial(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'J';
    }

    return trimmedName[0].toUpperCase();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unavailable';
    }

    final localDateTime = dateTime.toLocal();

    final day = localDateTime.day.toString().padLeft(2, '0');

    final month = localDateTime.month.toString().padLeft(2, '0');

    final hour = localDateTime.hour.toString().padLeft(2, '0');

    final minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/${localDateTime.year} '
        '$hour:$minute';
  }
}
