import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConfettiAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.onComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          color: _getRandomColor(),
          initialX: _random.nextDouble(),
          initialY: 0.5,
          velocityX: (_random.nextDouble() - 0.5) * 2,
          velocityY: -(_random.nextDouble() * 2 + 1),
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
          size: _random.nextDouble() * 8 + 4,
        ),
      );
    }
  }

  Color _getRandomColor() {
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.infoBlue,
      AppTheme.successGreen,
      AppTheme.warningOrange,
      Colors.pink,
      Colors.yellow,
    ];
    return colors[_random.nextInt(colors.length)];
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
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
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

class ConfettiParticle {
  final Color color;
  final double initialX;
  final double initialY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.initialX,
    required this.initialY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final gravity = 0.5;
      final x =
          size.width * (particle.initialX + particle.velocityX * progress);
      final y =
          size.height *
          (particle.initialY +
              particle.velocityY * progress +
              gravity * progress * progress);

      if (y > size.height) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
