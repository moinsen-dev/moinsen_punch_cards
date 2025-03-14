import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class SettingsProvider extends StatelessWidget {
  final Widget child;

  const SettingsProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SettingsService>(
      future: SettingsService.create(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final settingsService = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: settingsService,
            ),
            Provider<void Function(ThemeMode)>.value(
              value: (ThemeMode mode) async {
                await settingsService.setThemeMode(mode);
              },
            ),
          ],
          child: child,
        );
      },
    );
  }
}
