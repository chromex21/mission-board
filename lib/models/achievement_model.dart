class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final int requirement;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.requirement,
  });
}

enum AchievementType { missions, streak, points, speed, difficulty }

class Achievements {
  static const List<Achievement> all = [
    // Mission-based
    Achievement(
      id: 'first_mission',
      title: 'First Steps',
      description: 'Complete your first mission',
      icon: '🎯',
      type: AchievementType.missions,
      requirement: 1,
    ),
    Achievement(
      id: 'missions_10',
      title: 'Getting Started',
      description: 'Complete 10 missions',
      icon: '⭐',
      type: AchievementType.missions,
      requirement: 10,
    ),
    Achievement(
      id: 'missions_25',
      title: 'Committed',
      description: 'Complete 25 missions',
      icon: '🌟',
      type: AchievementType.missions,
      requirement: 25,
    ),
    Achievement(
      id: 'missions_50',
      title: 'Dedicated',
      description: 'Complete 50 missions',
      icon: '💫',
      type: AchievementType.missions,
      requirement: 50,
    ),
    Achievement(
      id: 'missions_100',
      title: 'Centurion',
      description: 'Complete 100 missions',
      icon: '🏆',
      type: AchievementType.missions,
      requirement: 100,
    ),

    // Streak-based
    Achievement(
      id: 'streak_3',
      title: 'On Fire',
      description: '3-day completion streak',
      icon: '🔥',
      type: AchievementType.streak,
      requirement: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Weekly Warrior',
      description: '7-day completion streak',
      icon: '⚡',
      type: AchievementType.streak,
      requirement: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Unstoppable',
      description: '30-day completion streak',
      icon: '🚀',
      type: AchievementType.streak,
      requirement: 30,
    ),

    // Points-based
    Achievement(
      id: 'points_500',
      title: 'Point Collector',
      description: 'Earn 500 points',
      icon: '💰',
      type: AchievementType.points,
      requirement: 500,
    ),
    Achievement(
      id: 'points_1000',
      title: 'Points Master',
      description: 'Earn 1,000 points',
      icon: '💎',
      type: AchievementType.points,
      requirement: 1000,
    ),
    Achievement(
      id: 'points_5000',
      title: 'Fortune Builder',
      description: 'Earn 5,000 points',
      icon: '👑',
      type: AchievementType.points,
      requirement: 5000,
    ),

    // Difficulty-based
    Achievement(
      id: 'difficulty_5',
      title: 'Challenge Seeker',
      description: 'Complete a level 5 mission',
      icon: '⚔️',
      type: AchievementType.difficulty,
      requirement: 5,
    ),
  ];

  // Check which achievements should be unlocked
  static List<String> checkAchievements({
    required int completedMissions,
    required int bestStreak,
    required int totalPoints,
    required int maxDifficulty,
    required List<String> currentAchievements,
  }) {
    final newAchievements = <String>[];

    for (final achievement in all) {
      // Skip if already unlocked
      if (currentAchievements.contains(achievement.id)) continue;

      bool unlocked = false;

      switch (achievement.type) {
        case AchievementType.missions:
          unlocked = completedMissions >= achievement.requirement;
          break;
        case AchievementType.streak:
          unlocked = bestStreak >= achievement.requirement;
          break;
        case AchievementType.points:
          unlocked = totalPoints >= achievement.requirement;
          break;
        case AchievementType.difficulty:
          unlocked = maxDifficulty >= achievement.requirement;
          break;
        case AchievementType.speed:
          // Speed achievements can be added later
          break;
      }

      if (unlocked) {
        newAchievements.add(achievement.id);
      }
    }

    return newAchievements;
  }

  // Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}
