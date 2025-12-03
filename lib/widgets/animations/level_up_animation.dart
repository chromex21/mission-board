import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LevelUpAnimation extends StatefulWidget {
  final int newLevel;
  final VoidCallback? onComplete;

  const LevelUpAnimation({super.key, required this.newLevel, this.onComplete});

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 2500));
    await _fadeController.reverse();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _fadeAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.grey900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withValues(
                        alpha: _glowAnimation.value,
                      ),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withValues(
                          alpha: 0.3 * _glowAnimation.value,
                        ),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 80,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You reached Level ${widget.newLevel}',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.grey400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
