// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'services/settings_service.dart';

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize settings service
  final settingsService = await SettingsService.create();

  // Initialize your app
  runApp(PunchCardApp(settingsService: settingsService));

  // Remove splash screen after 2 seconds
  await Future.delayed(const Duration(seconds: 2));
  FlutterNativeSplash.remove();
}
