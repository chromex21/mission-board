import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/achievement_model.dart';
import '../../core/theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appUser = authProvider.appUser;
    final unlockedIds = appUser?.achievements ?? [];
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkGrey : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.grey900 : Colors.white,
        title: Text(
          'Achievements',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightText,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppTheme.lightText,
        ),
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
              color: isDark ? AppTheme.grey900 : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppTheme.grey700 : AppTheme.lightBorder,
              ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: unlockedIds.length / Achievements.all.length,
                          backgroundColor: isDark ? AppTheme.grey700 : AppTheme.lightBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryPurple,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((unlockedIds.length / Achievements.all.length) * 100).toStringAsFixed(0)}% Complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.grey400 : AppTheme.lightSubtext,
                        ),
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
                  isDark: isDark,
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
  final bool isDark;

  const _CategorySection({
    required this.type,
    required this.achievements,
    required this.unlockedIds,
    required this.isDark,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.lightText,
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
            isDark: isDark,
          );
        }),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final bool isDark;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppTheme.grey900 : AppTheme.lightCard;
    final lockedBgColor = isDark
        ? AppTheme.grey900.withValues(alpha: 0.5)
        : AppTheme.lightCard.withValues(alpha: 0.5);
    final borderColor = isDark ? AppTheme.grey700 : AppTheme.lightBorder;
    final iconBgColor = isDark ? AppTheme.grey800 : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.white : AppTheme.lightText;
    final subtextColor = isDark ? AppTheme.grey400 : AppTheme.lightSubtext;
    final lockedColor = isDark ? AppTheme.grey600 : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? bgColor : lockedBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primaryPurple.withValues(alpha: 0.5)
              : borderColor,
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
                  : iconBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnlocked
                    ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                    : borderColor,
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
                    color: isUnlocked ? textColor : lockedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? subtextColor : lockedColor,
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
            Icon(Icons.lock, size: 20, color: lockedColor),
        ],
      ),
    );
  }
}
