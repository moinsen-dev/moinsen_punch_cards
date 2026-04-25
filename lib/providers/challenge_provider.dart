import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/challenge_service.dart';

class ChallengeProvider extends StatelessWidget {
  final Widget child;

  const ChallengeProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChallengeService(),
      child: child,
    );
  }
}
