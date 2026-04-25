import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _launchApp() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Widget _fadeSlide({
    required int delayMs,
    required Widget child,
    double slideY = 30,
  }) {
    final interval = Interval(
      (delayMs / 2800).clamp(0.0, 0.8),
      ((delayMs + 700) / 2800).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = interval.transform(_controller.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideY * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(30),
              colorScheme.secondary.withAlpha(20),
              colorScheme.tertiary.withAlpha(15),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),

                          _fadeSlide(
                            delayMs: 0,
                            child: _TopBar(colorScheme: colorScheme),
                          ),
                          const SizedBox(height: 48),

                          _fadeSlide(
                            delayMs: 100,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                      colorScheme.primaryContainer.withAlpha(80),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.grid_4x4,
                                  size: 80,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          _fadeSlide(
                            delayMs: 200,
                            child: Text(
                              'Punch Cards',
                              style: textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _fadeSlide(
                            delayMs: 300,
                            child: Text(
                              'Retro Computing, Reimagined',
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fadeSlide(
                            delayMs: 400,
                            child: Text(
                              'Create, edit, and learn about punch card programming — '
                              'powered by AI, built with love in Hamburg.',
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 40),

                          _fadeSlide(
                            delayMs: 500,
                            child: Center(
                              child: FilledButton(
                                onPressed: _launchApp,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 20,
                                  ),
                                  textStyle: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Try It Now'),
                                    SizedBox(width: 12),
                                    Icon(Icons.arrow_forward),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          _fadeSlide(
                            delayMs: 600,
                            child: _FeatureGrid(colorScheme: colorScheme),
                          ),
                          const SizedBox(height: 48),

                          _fadeSlide(
                            delayMs: 700,
                            child: _SectionHeader(
                              icon: Icons.auto_awesome,
                              title: 'Powered by AI',
                              subtitle:
                                  'Integrated with Google Gemini for intelligent punch card analysis, '
                                  'challenge validation, and interactive tutorials.',
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(height: 32),

                          _fadeSlide(
                            delayMs: 800,
                            child: _SectionHeader(
                              icon: Icons.palette,
                              title: 'Beautiful & Accessible',
                              subtitle:
                                  'Full dark mode support, Material 3 design, responsive layouts — '
                                  'works on mobile, tablet, and web.',
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(height: 48),

                          _fadeSlide(
                            delayMs: 850,
                            child: _AppPreview(colorScheme: colorScheme),
                          ),
                          const SizedBox(height: 48),

                          _fadeSlide(
                            delayMs: 900,
                            child: _TechStack(colorScheme: colorScheme),
                          ),
                          const SizedBox(height: 48),

                          _fadeSlide(
                            delayMs: 1000,
                            child: _CompanySection(
                              colorScheme: colorScheme,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 32),

                          _fadeSlide(
                            delayMs: 1100,
                            child: _Footer(colorScheme: colorScheme),
                          ),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ColorScheme colorScheme;

  const _TopBar({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.grid_4x4, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Text(
              'Moinsen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse('https://moinsen.dev')),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('moinsen.dev'),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final ColorScheme colorScheme;

  const _FeatureGrid({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(
        icon: Icons.edit_square,
        title: 'Visual Editor',
        description: 'Interactive 12x80 punch card grid with direct punch mode',
      ),
      _Feature(
        icon: Icons.extension,
        title: 'Challenges',
        description: 'Timed programming challenges validated by AI',
      ),
      _Feature(
        icon: Icons.school,
        title: 'Tutorials',
        description: 'Quiz-based learning with scoring and progression',
      ),
      _Feature(
        icon: Icons.phone_android,
        title: 'Cross-Platform',
        description: 'Web, Android, and iOS from a single codebase',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 2 : 1;
        return Column(
          children: List.generate(
            (features.length / columns).ceil(),
            (rowIndex) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: List.generate(columns, (colIndex) {
                  final i = rowIndex * columns + colIndex;
                  if (i >= features.length) {
                    return const Expanded(child: SizedBox.shrink());
                  }
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: colIndex == 0 ? 0 : 6,
                        right: colIndex == columns - 1 ? 0 : 6,
                      ),
                      child: _FeatureCard(
                        feature: features[i],
                        colorScheme: colorScheme,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final ColorScheme colorScheme;

  const _FeatureCard({required this.feature, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              feature.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              feature.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.secondary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechStack extends StatelessWidget {
  final ColorScheme colorScheme;

  const _TechStack({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final techs = [
      ('Flutter 3.24+', Icons.flutter_dash),
      ('Dart', Icons.code),
      ('Gemini AI', Icons.auto_awesome),
      ('Material 3', Icons.palette),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built With',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: techs.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.$2, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    t.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CompanySection extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;

  const _CompanySection({required this.colorScheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha(20),
            colorScheme.secondary.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.tertiary.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.record_voice_over,
              size: 36,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A Moinsen.dev Project',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Created by Ulrich Diedrichsen in Hamburg, Germany.\n'
            'Built with voice commands, AI assistance, and modern development tools.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => launchUrl(Uri.parse('https://moinsen.dev')),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 18),
                SizedBox(width: 8),
                Text('Visit moinsen.dev'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ColorScheme colorScheme;

  const _Footer({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Open Source • MIT License\n',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            children: [
              TextSpan(
                text: 'github.com/moinsen-dev/moinsen_punch_cards',
                style: TextStyle(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(
                        Uri.parse(
                          'https://github.com/moinsen-dev/moinsen_punch_cards',
                        ),
                      ),
              ),
              const TextSpan(text: '\n'),
              TextSpan(
                text: 'moinsen.dev',
                style: TextStyle(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse('https://moinsen.dev')),
              ),
              const TextSpan(text: ' • Hamburg, Germany'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _AppPreview extends StatelessWidget {
  final ColorScheme colorScheme;

  const _AppPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'See It In Action',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhoneMockup(
                  colorScheme: colorScheme,
                  label: 'Visual Editor',
                  child: _EditorMockup(colorScheme: colorScheme),
                ),
                if (isWide) const SizedBox(width: 24),
                if (isWide)
                  _PhoneMockup(
                    colorScheme: colorScheme,
                    label: 'Challenge Mode',
                    child: _GameMockup(colorScheme: colorScheme),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final ColorScheme colorScheme;
  final String label;
  final Widget child;

  const _PhoneMockup({
    required this.colorScheme,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 380,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline, width: 2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _EditorMockup extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EditorMockup({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2518),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Punch Card #1',
              style: TextStyle(color: Color(0xFFD4C48A), fontSize: 10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: List.generate(
                8,
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: List.generate(
                      16,
                      (col) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (row + col) % 5 == 0
                                ? const Color(0xFFFFCC00)
                                : const Color(0xFF1A1610),
                            border: Border.all(
                              color: const Color(0xFF6B5F3A),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              'LOAD → ADD → STORE',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameMockup extends StatelessWidget {
  final ColorScheme colorScheme;

  const _GameMockup({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1545),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withAlpha(80)),
            ),
            child: const Text(
              'What does the LOAD operation do?',
              style: TextStyle(color: Colors.white, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: i == 1
                      ? Colors.green.withAlpha(30)
                      : const Color(0xFF0A1545),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == 1
                        ? Colors.green.withAlpha(128)
                        : Colors.blue.withAlpha(80),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == 1 ? Colors.green : Colors.blue,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            color: i == 1 ? Colors.green : Colors.white,
                            fontSize: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        [
                          'Prints the value',
                          'Reads a value into memory',
                          'Saves to disk',
                          'Deletes a value',
                        ][i],
                        style: TextStyle(
                          color: i == 1 ? Colors.green[100] : Colors.white70,
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
