import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/backend_user_service.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({required this.signedInScreen, super.key});

  final Widget signedInScreen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AuthenticationErrorScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Checking authentication...');
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return _UserSyncGate(
          key: ValueKey(
            '${firebaseUser.uid}:'
            '${firebaseUser.displayName ?? ''}',
          ),
          displayName: firebaseUser.displayName,
          signedInScreen: signedInScreen,
        );
      },
    );
  }
}

class _UserSyncGate extends StatefulWidget {
  const _UserSyncGate({
    required this.displayName,
    required this.signedInScreen,
    super.key,
  });

  final String? displayName;
  final Widget signedInScreen;

  @override
  State<_UserSyncGate> createState() {
    return _UserSyncGateState();
  }
}

class _UserSyncGateState extends State<_UserSyncGate> {
  final BackendUserService _backendUserService = BackendUserService();

  late Future<AppUser> _syncFuture;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  void _startSync() {
    _syncFuture = _backendUserService.syncCurrentUser(name: widget.displayName);
  }

  void _retrySync() {
    setState(_startSync);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: _syncFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Preparing your account...');
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account Setup')),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 60),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to prepare account',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _retrySync,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _signOut,
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign Out'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return widget.signedInScreen;
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _AuthenticationErrorScreen extends StatelessWidget {
  const _AuthenticationErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Unable to determine authentication status.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
