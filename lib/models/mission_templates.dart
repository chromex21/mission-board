import '../models/mission_model.dart';

class MissionTemplate {
  final String id;
  final String title;
  final String description;
  final int reward;
  final int difficulty;
  final String category;
  final String icon;

  const MissionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.difficulty,
    required this.category,
    required this.icon,
  });

  Mission toMission(String createdBy, {MissionVisibility? visibility}) {
    return Mission(
      id: '',
      title: title,
      description: description,
      reward: reward,
      difficulty: difficulty,
      status: MissionStatus.open,
      createdBy: createdBy,
      visibility: visibility ?? MissionVisibility.private,
      templateId: id,
      createdAt: DateTime.now(),
    );
  }
}

class MissionTemplates {
  static const List<MissionTemplate> all = [
    // Health & Fitness
    MissionTemplate(
      id: 'workout_30min',
      title: '30-Minute Workout',
      description: 'Complete a 30-minute workout session',
      reward: 50,
      difficulty: 2,
      category: 'Health',
      icon: '💪',
    ),
    MissionTemplate(
      id: 'drink_water',
      title: 'Hydration Goal',
      description: 'Drink 8 glasses of water today',
      reward: 20,
      difficulty: 1,
      category: 'Health',
      icon: '💧',
    ),
    MissionTemplate(
      id: 'meditation',
      title: 'Meditation Session',
      description: 'Meditate for 15 minutes',
      reward: 30,
      difficulty: 1,
      category: 'Health',
      icon: '🧘',
    ),

    // Learning
    MissionTemplate(
      id: 'read_30min',
      title: 'Reading Time',
      description: 'Read for 30 minutes',
      reward: 40,
      difficulty: 1,
      category: 'Learning',
      icon: '📚',
    ),
    MissionTemplate(
      id: 'online_course',
      title: 'Course Lesson',
      description: 'Complete one online course lesson',
      reward: 60,
      difficulty: 2,
      category: 'Learning',
      icon: '🎓',
    ),
    MissionTemplate(
      id: 'practice_skill',
      title: 'Skill Practice',
      description: 'Practice a skill for 1 hour',
      reward: 80,
      difficulty: 3,
      category: 'Learning',
      icon: '🎯',
    ),

    // Productivity
    MissionTemplate(
      id: 'deep_work',
      title: 'Deep Work Session',
      description: 'Focus on important task for 2 hours uninterrupted',
      reward: 100,
      difficulty: 3,
      category: 'Productivity',
      icon: '⚡',
    ),
    MissionTemplate(
      id: 'clean_inbox',
      title: 'Inbox Zero',
      description: 'Clear and organize email inbox',
      reward: 40,
      difficulty: 2,
      category: 'Productivity',
      icon: '📧',
    ),
    MissionTemplate(
      id: 'plan_tomorrow',
      title: 'Plan Tomorrow',
      description: 'Plan and prioritize tasks for tomorrow',
      reward: 30,
      difficulty: 1,
      category: 'Productivity',
      icon: '📝',
    ),

    // Creative
    MissionTemplate(
      id: 'creative_project',
      title: 'Creative Work',
      description: 'Work on creative project for 1 hour',
      reward: 70,
      difficulty: 2,
      category: 'Creative',
      icon: '🎨',
    ),
    MissionTemplate(
      id: 'write_journal',
      title: 'Journal Entry',
      description: 'Write a reflective journal entry',
      reward: 30,
      difficulty: 1,
      category: 'Creative',
      icon: '✍️',
    ),

    // Social
    MissionTemplate(
      id: 'call_friend',
      title: 'Connect with Friend',
      description: 'Call or meet with a friend',
      reward: 40,
      difficulty: 1,
      category: 'Social',
      icon: '👥',
    ),
    MissionTemplate(
      id: 'help_someone',
      title: 'Help Someone',
      description: 'Do something helpful for another person',
      reward: 50,
      difficulty: 2,
      category: 'Social',
      icon: '🤝',
    ),

    // Home
    MissionTemplate(
      id: 'clean_room',
      title: 'Room Cleaning',
      description: 'Deep clean and organize a room',
      reward: 50,
      difficulty: 2,
      category: 'Home',
      icon: '🧹',
    ),
    MissionTemplate(
      id: 'cook_meal',
      title: 'Cook Healthy Meal',
      description: 'Prepare a healthy home-cooked meal',
      reward: 40,
      difficulty: 2,
      category: 'Home',
      icon: '🍳',
    ),
  ];

  static List<String> get categories {
    return all.map((t) => t.category).toSet().toList()..sort();
  }

  static List<MissionTemplate> getByCategory(String category) {
    return all.where((t) => t.category == category).toList();
  }

  static MissionTemplate? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
