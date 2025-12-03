import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/mission_model.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/cards/mission_card.dart';

class PersonalDashboardScreen extends StatelessWidget {
  const PersonalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    // Filter personal missions (created by user)
    final personalMissions = missionProvider.missions.where((mission) {
      return mission.createdBy == userId &&
          (mission.status == MissionStatus.open ||
              mission.status == MissionStatus.assigned);
    }).toList();

    // Filter by status
    final activeMissions = personalMissions
        .where(
          (m) =>
              m.status == MissionStatus.assigned ||
              m.status == MissionStatus.open,
        )
        .toList();

    // Get completed today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final completedToday = missionProvider.missions.where((mission) {
      return mission.createdBy == userId &&
          mission.status == MissionStatus.completed &&
          mission.completedAt != null &&
          mission.completedAt!.isAfter(todayStart);
    }).length;

    // Get completed this week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final completedThisWeek = missionProvider.missions.where((mission) {
      return mission.createdBy == userId &&
          mission.status == MissionStatus.completed &&
          mission.completedAt != null &&
          mission.completedAt!.isAfter(weekStartDate);
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your personal goals and habits',
                    style: TextStyle(fontSize: 14, color: AppTheme.grey400),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.assignment,
                          label: 'Active',
                          value: activeMissions.length.toString(),
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle,
                          label: 'Today',
                          value: completedToday.toString(),
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today,
                          label: 'This Week',
                          value: completedThisWeek.toString(),
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Row(
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.createPersonalMission,
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Mission'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickActionCard(
                          icon: Icons.fitness_center,
                          label: 'Workout',
                          onTap: () => _createFromTemplate(context, 'workout'),
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          icon: Icons.book,
                          label: 'Read',
                          onTap: () => _createFromTemplate(context, 'reading'),
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          icon: Icons.work,
                          label: 'Deep Work',
                          onTap: () =>
                              _createFromTemplate(context, 'deep_work'),
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          icon: Icons.self_improvement,
                          label: 'Meditate',
                          onTap: () =>
                              _createFromTemplate(context, 'meditation'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Text(
                        'Active Missions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activeMissions.length.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Mission List
          if (activeMissions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: AppTheme.grey600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active personal missions',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.grey400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first mission to get started',
                      style: TextStyle(fontSize: 14, color: AppTheme.grey600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.createPersonalMission,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Mission'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final mission = activeMissions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MissionCard(mission: mission),
                  );
                }, childCount: activeMissions.length),
              ),
            ),
        ],
      ),
    );
  }

  void _createFromTemplate(BuildContext context, String templateId) {
    // Navigate to create screen with template pre-selected
    Navigator.pushNamed(
      context,
      AppRoutes.createPersonalMission,
      arguments: templateId,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.grey400)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.grey900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.grey700),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryPurple, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
