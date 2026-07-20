import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/auth_gate.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const JelajahMyApp());
}

class JelajahMyApp extends StatelessWidget {
  const JelajahMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JelajahMY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(signedInScreen: MainShell()),
    );
  }
}
