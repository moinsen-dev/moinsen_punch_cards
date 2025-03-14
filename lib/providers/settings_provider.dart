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
    return FutureBuilder(
      future: () async {
        final service = SettingsService();
        await service.init();
        return service;
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final settingsService = snapshot.data!;

        return ChangeNotifierProvider<SettingsService>.value(
          value: settingsService,
          child: child,
        );
      },
    );
  }
}
