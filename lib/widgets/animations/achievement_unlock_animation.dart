import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AchievementUnlockAnimation extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onComplete;

  const AchievementUnlockAnimation({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onComplete,
  });

  @override
  State<AchievementUnlockAnimation> createState() =>
      _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _shakeAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _shakeController.forward();
    await _shakeController.reverse();
    await Future.delayed(const Duration(milliseconds: 2000));
    await _slideController.reverse();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 16,
      left: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.rotate(angle: _shakeAnimation.value, child: child);
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryPurple.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: AppTheme.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
