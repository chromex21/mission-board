import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/mission_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../widgets/layout/app_layout.dart';

enum TimePeriod { today, week, month, all }

class HistoryScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const HistoryScreen({super.key, this.onNavigate});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TimePeriod _selectedPeriod = TimePeriod.all;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, y').format(date);
  }

  String _getTimeTaken(DateTime? assignedAt, DateTime? completedAt) {
    if (assignedAt == null || completedAt == null) return '';
    final duration = completedAt.difference(assignedAt);
    if (duration.inDays > 0) return '${duration.inDays}d';
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }

  List<Mission> _filterByPeriod(List<Mission> missions) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.today:
        final todayStart = DateTime(now.year, now.month, now.day);
        return missions.where((m) {
          final date = m.completedAt;
          return date != null && date.isAfter(todayStart);
        }).toList();
      case TimePeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        return missions.where((m) {
          final date = m.completedAt;
          return date != null && date.isAfter(weekStartDate);
        }).toList();
      case TimePeriod.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return missions.where((m) {
          final date = m.completedAt;
          return date != null && date.isAfter(monthStart);
        }).toList();
      case TimePeriod.all:
        return missions;
    }
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return 'Today';
      case TimePeriod.week:
        return 'This Week';
      case TimePeriod.month:
        return 'This Month';
      case TimePeriod.all:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    final appUser = authProvider.appUser;

    final completedMissions = _filterByPeriod(
      missionProvider.missions
          .where(
            (m) =>
                m.status == MissionStatus.completed && m.assignedTo == userId,
          )
          .toList(),
    );

    return AppLayout(
      currentRoute: '/missions/history',
      title: 'Mission History',
      onNavigate: widget.onNavigate ?? (route) {},
      child: Column(
        children: [
          // Time period filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimePeriod.values.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getPeriodLabel(period)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      backgroundColor: AppTheme.grey900,
                      selectedColor: AppTheme.primaryPurple.withValues(
                        alpha: 0.3,
                      ),
                      checkmarkColor: AppTheme.primaryPurple,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.white : AppTheme.grey400,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryPurple
                            : AppTheme.grey700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Stats header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grey900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.grey700),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline,
                        label: 'Completed',
                        value: '${appUser?.completedMissions ?? 0}',
                        color: AppTheme.successGreen,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppTheme.grey700),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.stars_rounded,
                        label: 'Total Points',
                        value: '${appUser?.totalPoints ?? 0}',
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppTheme.grey700),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up,
                        label: 'Level',
                        value: '${appUser?.level ?? 1}',
                        color: AppTheme.infoBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.grey800,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.grey700),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: AppTheme.warningOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Current Streak: ${appUser?.currentStreak ?? 0} days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grey200,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 20, color: AppTheme.grey700),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Best: ${appUser?.bestStreak ?? 0} days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grey200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: completedMissions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: AppTheme.grey600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No completed missions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.grey400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete missions to see them here',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: completedMissions.length,
                    itemBuilder: (context, index) {
                      final mission = completedMissions[index];
                      final timeTaken = _getTimeTaken(
                        mission.assignedAt,
                        mission.completedAt,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.grey900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.grey700),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppTheme.successGreen.withValues(
                                          alpha: 0.3,
                                        ),
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
                                          'COMPLETED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.stars_rounded,
                                    size: 14,
                                    color: AppTheme.primaryPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${mission.reward}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mission.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.white,
                                ),
                              ),
                              if (mission.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mission.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.grey400,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: AppTheme.grey600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(mission.completedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.grey400,
                                    ),
                                  ),
                                  if (timeTaken.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 12,
                                      color: AppTheme.grey600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeTaken,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.grey400,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.signal_cellular_alt,
                                    size: 12,
                                    color: AppTheme.grey600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lvl ${mission.difficulty}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.grey400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.white,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
      ],
    );
  }
}
