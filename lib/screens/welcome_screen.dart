import 'package:flutter/material.dart';

import '../widgets/info_carousel.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGetStarted(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(50),
              Theme.of(context).colorScheme.secondary.withAlpha(50),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_column_rounded,
                            size: 100,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome to MoinsenPunchcard',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your Modern Punch Card Processor',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Process and generate punch cards with ease',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          const InfoCarousel(),
                          const SizedBox(height: 32),
                          _buildGetStartedButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: const Text(
                    'Generated with ❤️ by Claude using VibeCoding - Ulrich Diedrichsen - Moinsen.dev',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _onGetStarted(context),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      icon: const Icon(Icons.arrow_forward),
      label: const Text('Get Started', style: TextStyle(fontSize: 18)),
    );
  }
}
