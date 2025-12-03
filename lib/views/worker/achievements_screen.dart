import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/achievement_model.dart';
import '../../core/theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appUser = authProvider.appUser;
    final unlockedIds = appUser?.achievements ?? [];

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Go back',
        ),
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grey900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.grey700),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${unlockedIds.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${unlockedIds.length} / ${Achievements.all.length} Unlocked',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: unlockedIds.length / Achievements.all.length,
                          backgroundColor: AppTheme.grey700,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryPurple,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((unlockedIds.length / Achievements.all.length) * 100).toStringAsFixed(0)}% Complete',
                        style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Achievement categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: AchievementType.values.length,
              itemBuilder: (context, index) {
                final type = AchievementType.values[index];
                final categoryAchievements = Achievements.all
                    .where((a) => a.type == type)
                    .toList();

                return _CategorySection(
                  type: type,
                  achievements: categoryAchievements,
                  unlockedIds: unlockedIds,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AchievementType type;
  final List<Achievement> achievements;
  final List<String> unlockedIds;

  const _CategorySection({
    required this.type,
    required this.achievements,
    required this.unlockedIds,
  });

  String _getTypeName() {
    switch (type) {
      case AchievementType.missions:
        return 'Missions';
      case AchievementType.streak:
        return 'Streaks';
      case AchievementType.points:
        return 'Points';
      case AchievementType.difficulty:
        return 'Challenges';
      case AchievementType.speed:
        return 'Speed';
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case AchievementType.missions:
        return Icons.task_alt;
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.points:
        return Icons.stars_rounded;
      case AchievementType.difficulty:
        return Icons.military_tech;
      case AchievementType.speed:
        return Icons.speed;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(_getTypeIcon(), size: 18, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text(
                _getTypeName(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
        ),
        ...achievements.map((achievement) {
          final isUnlocked = unlockedIds.contains(achievement.id);
          return _AchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
          );
        }),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({required this.achievement, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppTheme.grey900
            : AppTheme.grey900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primaryPurple.withValues(alpha: 0.5)
              : AppTheme.grey700,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.primaryPurple.withValues(alpha: 0.15)
                  : AppTheme.grey800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnlocked
                    ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                    : AppTheme.grey700,
              ),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? AppTheme.white : AppTheme.grey600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? AppTheme.grey400 : AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ),

          // Status
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.successGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: AppTheme.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'UNLOCKED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            Icon(Icons.lock, size: 20, color: AppTheme.grey600),
        ],
      ),
    );
  }
}
