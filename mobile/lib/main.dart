import 'package:flutter/material.dart';

import 'screens/attraction_list_screen.dart';

void main() {
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
      home: const AttractionListScreen(),
    );
  }
}
