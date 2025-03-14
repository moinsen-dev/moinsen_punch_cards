import 'package:flutter/material.dart';

import 'challenge_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose Your Mode',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const Expanded(
              child: _GameCards(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCards extends StatefulWidget {
  const _GameCards();

  @override
  State<_GameCards> createState() => _GameCardsState();
}

class _GameCardsState extends State<_GameCards> with TickerProviderStateMixin {
  late final AnimationController _challengeController;
  late final AnimationController _tutorialController;
  late final Animation<double> _challengeRotation;
  late final Animation<double> _tutorialRotation;
  late final Animation<double> _challengeScale;
  late final Animation<double> _tutorialScale;

  @override
  void initState() {
    super.initState();
    _challengeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _tutorialController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _challengeRotation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _challengeController,
      curve: Curves.easeInOut,
    ));

    _tutorialRotation = Tween<double>(
      begin: 0.02,
      end: -0.02,
    ).animate(CurvedAnimation(
      parent: _tutorialController,
      curve: Curves.easeInOut,
    ));

    _challengeScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _challengeController,
      curve: Curves.easeInOut,
    ));

    _tutorialScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _tutorialController,
      curve: Curves.easeInOut,
    ));

    // Start the animations with a slight delay between them
    Future.delayed(const Duration(milliseconds: 500), () {
      _tutorialController.forward();
    });
  }

  @override
  void dispose() {
    _challengeController.dispose();
    _tutorialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _challengeController,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(_challengeRotation.value)
                    ..scale(_challengeScale.value),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: _GameCard(
                title: 'Challenge Mode',
                description:
                    'Test your skills with computer-generated programming challenges!',
                icon: Icons.extension,
                color: Theme.of(context).colorScheme.primaryContainer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengeScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _tutorialController,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(_tutorialRotation.value)
                    ..scale(_tutorialScale.value),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: _GameCard(
                title: 'Tutorial Mode',
                description:
                    'Learn the basics of punch card programming with guided lessons!',
                icon: Icons.school,
                color: Theme.of(context).colorScheme.secondaryContainer,
                onTap: () {
                  // TODO: Navigate to tutorial screen
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: textColor,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
