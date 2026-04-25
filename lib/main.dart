// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // Initialize your app
  runApp(const App());

  if (!kIsWeb) {
    // Remove splash screen after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove();
  }
}
