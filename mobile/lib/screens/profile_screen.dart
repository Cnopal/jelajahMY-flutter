import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/backend_user_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BackendUserService _userService = BackendUserService();

  final AuthService _authService = AuthService();

  late Future<AppUser> _userFuture;

  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _userFuture = _userService.getCurrentUser();
  }

  void _refreshProfile() {
    setState(_loadProfile);
  }

  Future<void> _openEditProfile(AppUser user) async {
    final updatedUser = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute<AppUser>(
        builder: (context) {
          return EditProfileScreen(user: user);
        },
      ),
    );

    if (updatedUser != null && mounted) {
      _refreshProfile();
    }
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: FutureBuilder<AppUser>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ProfileErrorView(
                message: snapshot.error.toString(),
                onRetry: _refreshProfile,
              );
            }

            final user = snapshot.data;

            if (user == null) {
              return _ProfileErrorView(
                message: 'Profile data is unavailable.',
                onRetry: _refreshProfile,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshProfile();
                await _userFuture;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text('Phone number'),
                          subtitle: Text(user.phone ?? 'Not provided'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.public_outlined),
                          title: const Text('Nationality'),
                          subtitle: Text(user.nationality ?? 'Not provided'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            user.emailVerified
                                ? Icons.verified_outlined
                                : Icons.warning_amber_outlined,
                          ),
                          title: const Text('Email status'),
                          subtitle: Text(
                            user.emailVerified ? 'Verified' : 'Not verified',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        _openEditProfile(user);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isSigningOut ? null : _confirmSignOut,
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(
                        _isSigningOut ? 'Signing Out...' : 'Sign Out',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _getInitial(user.name),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(user.email, textAlign: TextAlign.center),
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
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_off_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
