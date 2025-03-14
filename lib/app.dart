// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'package:flutter/material.dart';
import 'package:moinsen_punch_cards/screens/tutor_screen.dart';
import 'package:moinsen_punch_cards/screens/welcome_screen.dart';

import 'screens/punch_card_editor.dart';
import 'screens/settings_screen.dart';
import 'services/settings_service.dart';

// =============================================================================
// MAIN APPLICATION POINT
// =============================================================================

/// Main application widget
class PunchCardApp extends StatelessWidget {
  const PunchCardApp({
    super.key,
    required this.settingsService,
  });

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'app',
      onGenerateTitle: (BuildContext context) => 'Punch Card App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/main': (context) => MainScreen(settingsService: settingsService),
      },
    );
  }
}

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  final SettingsService settingsService;

  const MainScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settingsService.getThemeMode();
  }

  void _handleThemeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    widget.settingsService.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PunchCardEditor(settingsService: widget.settingsService),
          const TutorScreen(),
          SettingsScreen(
            settingsService: widget.settingsService,
            onThemeChanged: _handleThemeChanged,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.grid_4x4),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
