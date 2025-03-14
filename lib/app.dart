// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'package:flutter/material.dart';

import 'punchcard.dart';
import 'punchcard_generator.dart';
import 'screens/punch_card_editor.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/settings_service.dart';

// =============================================================================
// MAIN APPLICATION POINT
// =============================================================================

/// Main application widget
class PunchCardApp extends StatefulWidget {
  const PunchCardApp({super.key});

  @override
  State<PunchCardApp> createState() => _PunchCardAppState();
}

class _PunchCardAppState extends State<PunchCardApp> {
  late SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.system; // Default value

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsService = await SettingsService.create();
    if (mounted) {
      setState(() {
        _themeMode = _settingsService.getThemeMode();
      });
    }
  }

  void _handleThemeChanged(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    await _settingsService.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoinsenPunchcard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/main': (context) => PunchCardMainScreen(
              onThemeChanged: _handleThemeChanged,
              currentTheme: _themeMode,
            ),
      },
    );
  }
}

/// Main screen with bottom navigation
class PunchCardMainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const PunchCardMainScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<PunchCardMainScreen> createState() => _PunchCardMainScreenState();
}

class _PunchCardMainScreenState extends State<PunchCardMainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late SettingsService _settingsService;
  List<Widget>? _pages; // Change to nullable type

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsService = await SettingsService.create();
    setState(() {
      _pages = [
        const HomePage(), // Process Card page
        PunchCardGeneratorApp(
            onThemeChanged: widget.onThemeChanged), // Generate Card page
        PunchCardEditor(settingsService: _settingsService), // Editor page
      ];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MoinsenPunchcard Features'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                'Process Cards',
                'Upload and process physical punch cards:',
                [
                  'Camera capture support',
                  'Image processing and recognition',
                  'Execute punch card instructions',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Generate Cards',
                'Create new punch cards:',
                [
                  'AI-powered text to punch card conversion',
                  'SVG and PNG export options',
                  'Copy to clipboard functionality',
                  'Save and share capabilities',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Edit Cards',
                'Create and edit punch cards manually:',
                [
                  'Visual punch card editor',
                  'Add/edit/delete instructions',
                  'Live preview of the punch card',
                  'Save and manage multiple cards',
                  'Support for all punch card operations',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection('Settings', 'Customize your experience:', [
                'Theme customization (Light/Dark/System)',
                'API key configuration',
                'Processing preferences',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    String title,
    String subtitle,
    List<String> features,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle),
        const SizedBox(height: 8),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const Text('• '), Expanded(child: Text(feature))],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoinsenPunchcard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _openHelp(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  settingsService: _settingsService,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages == null
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _pages![_selectedIndex],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.input),
            label: 'Process Card',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Generate Card',
          ),
          NavigationDestination(
            icon: Icon(Icons.code),
            label: 'Programmer',
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              trailing: DropdownButton<ThemeMode>(
                value: widget.currentTheme,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                onChanged: (ThemeMode? newMode) {
                  if (newMode != null) {
                    widget.onThemeChanged(newMode);
                  }
                },
              ),
            ),
            const Divider(),
            const AboutListTile(
              icon: Icon(Icons.info),
              applicationName: 'MoinsenPunchcard',
              applicationVersion: '1.0.0',
              applicationLegalese: '©2024 Moinsen',
              child: Text('About'),
            ),
          ],
        ),
      ),
    );
  }
}
