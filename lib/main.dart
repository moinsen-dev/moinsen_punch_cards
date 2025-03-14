// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'package:flutter/material.dart';

import 'app.dart';

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punch Card Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PunchCardApp(),
    );
  }
}
