import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/user_model.dart';
import '../../models/mission_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/profile/mission_id_card.dart';
import '../../widgets/layout/app_layout.dart';
import '../../widgets/dialogs/edit_profile_dialog.dart';
import '../../utils/responsive_helper.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  // ignore: unused_field
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    final appUser = authProvider.appUser;

    if (appUser == null) {
      return AppLayout(
        currentRoute: '/profile',
        title: 'Profile',
        onNavigate: widget.onNavigate ?? (route) {},
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate stats
    final userId = authProvider.user?.uid ?? '';
    final completedMissions = missionProvider.missions
        .where(
          (m) => m.assignedTo == userId && m.status == MissionStatus.completed,
        )
        .toList();

    final personalMissions = missionProvider.missions
        .where((m) => m.createdBy == userId)
        .length;

    final teamMissions = completedMissions
        .where((m) => m.createdBy != userId)
        .length;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final weeklyPoints = completedMissions
        .where(
          (m) => m.completedAt != null && m.completedAt!.isAfter(weekStartDate),
        )
        .fold<int>(0, (sum, m) => sum + m.reward);

    final monthStart = DateTime(now.year, now.month, 1);
    final monthlyPoints = completedMissions
        .where(
          (m) => m.completedAt != null && m.completedAt!.isAfter(monthStart),
        )
        .fold<int>(0, (sum, m) => sum + m.reward);

    return AppLayout(
      currentRoute: '/profile',
      title: 'Profile',
      onNavigate: widget.onNavigate ?? (route) {},
      child: ResponsiveContent(
        maxWidth: AppSizing.maxContentWidth(context),
        child: SingleChildScrollView(
          padding: AppPadding.page(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/achievements');
                    },
                    icon: const Icon(Icons.emoji_events, size: 16),
                    label: const Text('Achievements'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                      side: BorderSide(color: AppTheme.primaryPurple),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditProfileDialog(user: appUser),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mission ID Card
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: MissionIdCard(user: appUser),
                ),
              ),

              const SizedBox(height: 24),

              // Profile Header (simplified)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.grey900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.grey700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.primaryPurple.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.grey700,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              appUser.email.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appUser.email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppUser.getRankTitle(appUser.level),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Level Progress
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.grey800,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.grey700),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Level ${appUser.level}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                  Text(
                                    'Level ${appUser.level + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.grey400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  final progress =
                                      (appUser.totalPoints % 100) / 100;
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 12,
                                        backgroundColor: AppTheme.grey700,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.primaryPurple,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${appUser.totalPoints % 100} / 100 XP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Member Since
                        Text(
                          'Member since ${DateFormat('MMMM yyyy').format(appUser.createdAt ?? DateTime.now())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.stars_rounded,
                              label: 'Total Points',
                              value: appUser.totalPoints.toString(),
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle,
                              label: 'Completed',
                              value: appUser.completedMissions.toString(),
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_fire_department,
                              label: 'Current Streak',
                              value: '${appUser.currentStreak} days',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.emoji_events,
                              label: 'Best Streak',
                              value: '${appUser.bestStreak} days',
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Activity Stats
                      const Text(
                        'Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.grey900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.grey700),
                        ),
                        child: Column(
                          children: [
                            _ActivityRow(
                              icon: Icons.calendar_today,
                              label: 'This Week',
                              value: '$weeklyPoints pts',
                              color: AppTheme.infoBlue,
                            ),
                            Divider(height: 1, color: AppTheme.grey700),
                            _ActivityRow(
                              icon: Icons.calendar_month,
                              label: 'This Month',
                              value: '$monthlyPoints pts',
                              color: AppTheme.primaryPurple,
                            ),
                            Divider(height: 1, color: AppTheme.grey700),
                            _ActivityRow(
                              icon: Icons.people,
                              label: 'Team Missions',
                              value: teamMissions.toString(),
                              color: AppTheme.successGreen,
                            ),
                            Divider(height: 1, color: AppTheme.grey700),
                            _ActivityRow(
                              icon: Icons.person,
                              label: 'Personal Missions',
                              value: personalMissions.toString(),
                              color: AppTheme.primaryPurple,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Achievements Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/achievements');
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.grey900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.grey700),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 40,
                              color: AppTheme.primaryPurple,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${appUser.achievements.length} Unlocked',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Keep completing missions to unlock more!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.grey400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.grey600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppTheme.white),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey200,
            ),
          ),
        ],
      ),
    );
  }
}
