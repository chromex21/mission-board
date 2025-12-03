import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppTheme.grey800, AppTheme.grey700, AppTheme.grey800],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MissionCardSkeleton extends StatelessWidget {
  const MissionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 80, height: 12, borderRadius: 6),
              const Spacer(),
              SkeletonLoader(width: 60, height: 12, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonLoader(width: double.infinity, height: 16, borderRadius: 6),
          const SizedBox(height: 8),
          SkeletonLoader(width: 200, height: 14, borderRadius: 6),
          const SizedBox(height: 16),
          Row(
            children: [
              SkeletonLoader(width: 100, height: 12, borderRadius: 6),
              const SizedBox(width: 16),
              SkeletonLoader(width: 80, height: 12, borderRadius: 6),
              const Spacer(),
              SkeletonLoader(width: 60, height: 12, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class TeamCardSkeleton extends StatelessWidget {
  const TeamCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Row(
        children: [
          SkeletonLoader(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 150, height: 16, borderRadius: 6),
                const SizedBox(height: 8),
                SkeletonLoader(width: 100, height: 12, borderRadius: 6),
              ],
            ),
          ),
          SkeletonLoader(width: 80, height: 32, borderRadius: 16),
        ],
      ),
    );
  }
}

class LeaderboardCardSkeleton extends StatelessWidget {
  const LeaderboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Row(
        children: [
          SkeletonLoader(width: 32, height: 32, borderRadius: 16),
          const SizedBox(width: 12),
          SkeletonLoader(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 16, borderRadius: 6),
                const SizedBox(height: 8),
                SkeletonLoader(width: 80, height: 12, borderRadius: 6),
              ],
            ),
          ),
          SkeletonLoader(width: 60, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}
