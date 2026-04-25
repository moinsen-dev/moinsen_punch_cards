import 'dart:math';

import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const ConfettiOverlay({
    super.key,
    required this.isActive,
    required this.child,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.isActive) {
          _spawnParticles();
          _controller.forward(from: 0);
        }
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _spawnParticles();
      _controller.forward(from: 0);
    } else if (!widget.isActive) {
      _controller.stop();
      _particles.clear();
    }
  }

  void _spawnParticles() {
    _particles.clear();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.indigo,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    for (int i = 0; i < 40; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        startY: -0.1 - _random.nextDouble() * 0.2,
        speed: 0.3 + _random.nextDouble() * 0.5,
        drift: (_random.nextDouble() - 0.5) * 0.3,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6,
        size: 4 + _random.nextDouble() * 6,
        color: colors[_random.nextInt(colors.length)],
        isCircle: _random.nextBool(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double drift;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.startY + p.speed * progress) * size.height;
      final x = (p.x + p.drift * progress) * size.width;
      final rotation = p.rotation + p.rotationSpeed * progress;
      final opacity = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        );
        canvas.drawRect(rect, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
