// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/challenge_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/challenge_screen.dart';
import 'screens/punch_card_editor.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/settings_service.dart';

// =============================================================================
// MAIN APPLICATION POINT
// =============================================================================

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsProvider(
      child: ChallengeProvider(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              title: 'Moinsen Punch Cards',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              themeMode: context.watch<SettingsService>().getThemeMode(),
              initialRoute: '/',
              routes: {
                '/': (context) => const WelcomeScreen(),
                '/main': (context) => const MainScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PunchCardEditor(settingsService: settingsService),
          const ChallengeScreen(),
          SettingsScreen(
            settingsService: settingsService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_4x4),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension),
            label: 'Challenge',
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
