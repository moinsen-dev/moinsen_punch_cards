import 'package:flutter/material.dart';

import 'challenge_screen.dart';
import 'tutor_screen.dart';

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

class _ZoomPageTransition extends PageRouteBuilder {
  final Widget page;
  final Offset centerOffset;

  _ZoomPageTransition({required this.page, required this.centerOffset})
      : super(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final screenSize = MediaQuery.of(context).size;

            // Calculate the scale to fill the screen
            final scale = animation.drive(
              Tween(
                begin: 0.9,
                end: 1.0, // Scale to full screen
              ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            );

            // Calculate offset to keep the card centered while zooming
            final offsetX = animation.drive(
              Tween(
                begin: centerOffset.dx,
                end: 0.0, // End at screen left edge
              ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            );

            final offsetY = animation.drive(
              Tween(
                begin: centerOffset.dy,
                end: 0.0, // End at screen top edge
              ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            );

            // Fade out other content
            final fadeOut = animation.drive(
              Tween(begin: 1.0, end: 0.0)
                  .chain(CurveTween(curve: const Interval(0.0, 0.3))),
            );

            return Stack(
              children: [
                // Fade out original content
                Opacity(
                  opacity: fadeOut.value,
                  child: const GameScreen(),
                ),
                // Zoom in selected card
                Transform(
                  transform: Matrix4.identity()
                    ..translate(offsetX.value, offsetY.value)
                    ..scale(scale.value),
                  alignment: Alignment.topLeft, // Change alignment to top-left
                  child: SizedBox(
                    width: screenSize.width,
                    height: screenSize.height,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
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
    );

    _tutorialController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

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
      begin: 0.9,
      end: 0.945,
    ).animate(CurvedAnimation(
      parent: _challengeController,
      curve: Curves.easeInOut,
    ));

    _tutorialScale = Tween<double>(
      begin: 0.9,
      end: 0.945,
    ).animate(CurvedAnimation(
      parent: _tutorialController,
      curve: Curves.easeInOut,
    ));

    // Start both animations with different delays and make them run forever
    _challengeController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 200), () {
      _tutorialController.repeat(reverse: true);
    });
  }

  void _navigateWithZoom(BuildContext context, Widget page, Offset cardCenter) {
    Navigator.of(context).push(
      _ZoomPageTransition(
        page: page,
        centerOffset: cardCenter,
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Transform.scale(
              scale: 0.9,
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
                    final RenderBox card =
                        context.findRenderObject() as RenderBox;
                    final Offset cardCenter =
                        card.localToGlobal(card.size.center(Offset.zero));
                    _navigateWithZoom(
                      context,
                      const ChallengeScreen(),
                      cardCenter,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Transform.scale(
              scale: 0.9,
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
                    final RenderBox card =
                        context.findRenderObject() as RenderBox;
                    final Offset cardCenter =
                        card.localToGlobal(card.size.center(Offset.zero));
                    _navigateWithZoom(
                      context,
                      const TutorScreen(),
                      cardCenter,
                    );
                  },
                ),
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
