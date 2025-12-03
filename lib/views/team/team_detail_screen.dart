import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/team_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mission_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart' show AppUser;
import '../../models/mission_model.dart';
import '../../routes/app_routes.dart';
import '../admin/create_team_mission_screen.dart';
import '../../utils/notification_helper.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    final team = teamProvider.getTeamById(widget.teamId);

    if (team == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkGrey,
        appBar: AppBar(
          title: const Text('Team Not Found'),
          backgroundColor: AppTheme.grey900,
        ),
        body: const Center(child: Text('Team not found')),
      );
    }

    final userRole = team.getUserRole(userId);
    final isAdmin = team.isAdminOrOwner(userId);

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      appBar: AppBar(
        title: Text(team.name),
        backgroundColor: AppTheme.grey900,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => showDialog(
                context: context,
                builder: (context) =>
                    _TeamSettingsDialog(team: team, userRole: userRole),
              ),
              tooltip: 'Team settings',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTeamHeader(team, userRole),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(team: team, isAdmin: isAdmin),
                _MissionsTab(teamId: team.id),
                _ActivityTab(teamId: team.id),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin && _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateTeamMissionScreen(teamId: team.id),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Mission'),
              backgroundColor: AppTheme.primaryPurple,
              tooltip: 'Create team mission',
              heroTag: 'create_team_mission',
            )
          : null,
    );
  }

  Widget _buildTeamHeader(Team team, TeamRole role) {
    return Container(
      color: AppTheme.grey900,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
            child: Text(
              team.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            team.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (team.description != null) ...[
            const SizedBox(height: 8),
            Text(
              team.description!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey600, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoleBadge(role),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.grey800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: AppTheme.grey400),
                    const SizedBox(width: 4),
                    Text(
                      '${team.totalMembers}',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Team ID: ${team.id.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.grey600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(TeamRole role) {
    Color color;
    String label;

    switch (role) {
      case TeamRole.owner:
        color = AppTheme.primaryPurple;
        label = 'Owner';
        break;
      case TeamRole.admin:
        color = Colors.blue;
        label = 'Admin';
        break;
      case TeamRole.member:
        color = AppTheme.grey600;
        label = 'Member';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.grey900,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryPurple,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.grey600,
        tabs: const [
          Tab(icon: Icon(Icons.people, size: 16), text: 'Members'),
          Tab(icon: Icon(Icons.task_alt, size: 16), text: 'Missions'),
          Tab(icon: Icon(Icons.history, size: 16), text: 'Activity'),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final Team team;
  final bool isAdmin;

  const _MembersTab({required this.team, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final allMemberIds = team.allMemberIds;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: allMemberIds.isEmpty ? [''] : allMemberIds,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading team members...',
                  style: TextStyle(color: AppTheme.grey400),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppTheme.grey600),
                const SizedBox(height: 16),
                Text(
                  'No members found',
                  style: TextStyle(color: AppTheme.grey400),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs
            .map(
              (doc) =>
                  AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        return Column(
          children: [
            if (users.length == 1 && isAdmin)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.infoBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'re the only member. Share your team ID with others so they can join!',
                        style: TextStyle(
                          color: AppTheme.infoBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final role = team.getUserRole(user.uid);
                  return _MemberCard(
                    user: user,
                    role: role,
                    team: team,
                    isAdmin: isAdmin,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final AppUser user;
  final TeamRole role;
  final Team team;
  final bool isAdmin;

  const _MemberCard({
    required this.user,
    required this.role,
    required this.team,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == TeamRole.owner;

    return Card(
      color: AppTheme.grey900,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.grey700),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
          child: Text(
            user.email[0].toUpperCase(),
            style: const TextStyle(color: AppTheme.primaryPurple),
          ),
        ),
        title: Text(user.email),
        subtitle: Text(
          '${user.totalPoints} points • Level ${user.level}',
          style: TextStyle(color: AppTheme.grey600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleBadge(role),
            if (isAdmin && !isOwner) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.grey600),
                onSelected: (value) => _handleMemberAction(context, value),
                itemBuilder: (context) => [
                  if (role == TeamRole.member)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Text('Promote to Admin'),
                    ),
                  if (role == TeamRole.admin)
                    const PopupMenuItem(
                      value: 'demote',
                      child: Text('Demote to Member'),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from Team'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(TeamRole role) {
    Color color;
    String label;

    switch (role) {
      case TeamRole.owner:
        color = AppTheme.primaryPurple;
        label = 'Owner';
        break;
      case TeamRole.admin:
        color = Colors.blue;
        label = 'Admin';
        break;
      case TeamRole.member:
        color = AppTheme.grey600;
        label = 'Member';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleMemberAction(BuildContext context, String action) async {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);

    try {
      switch (action) {
        case 'promote':
          await teamProvider.promoteToAdmin(team.id, user.uid);
          if (context.mounted) {
            context.showSuccess('\${user.email} promoted to admin');
          }
          break;
        case 'demote':
          await teamProvider.demoteToMember(team.id, user.uid);
          if (context.mounted) {
            context.showSuccess('\${user.email} demoted to member');
          }
          break;
        case 'remove':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remove Member'),
              content: Text('Remove \${user.email} from the team?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await teamProvider.removeMember(team.id, user.uid);
            if (context.mounted) {
              context.showSuccess('\${user.email} removed from team');
            }
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        context.showError('Error: ${e.toString()}');
      }
    }
  }
}

class _MissionsTab extends StatelessWidget {
  final String teamId;

  const _MissionsTab({required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionProvider>(
      builder: (context, missionProvider, child) {
        final teamMissions = missionProvider.missions
            .where((m) => m.teamId == teamId)
            .toList();

        if (missionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamMissions.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teamMissions.length,
          itemBuilder: (context, index) {
            final mission = teamMissions[index];
            return _MissionCard(mission: mission);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final team = teamProvider.getTeamById(teamId);
    final userId = authProvider.user?.uid ?? '';
    final isAdmin = team?.isAdminOrOwner(userId) ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: AppTheme.grey600),
          const SizedBox(height: 16),
          Text(
            'No team missions yet',
            style: TextStyle(color: AppTheme.grey600, fontSize: 16),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              'Create the first mission for your team',
              style: TextStyle(color: AppTheme.grey400, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateTeamMissionScreen(teamId: teamId),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Mission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (mission.status) {
      case MissionStatus.completed:
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case MissionStatus.assigned:
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.hourglass_empty;
        break;
      case MissionStatus.pendingReview:
        statusColor = AppTheme.infoBlue;
        statusIcon = Icons.rate_review;
        break;
      default:
        statusColor = AppTheme.grey600;
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      color: AppTheme.grey900,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.grey700),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.missionDetail,
            arguments: mission,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          mission.status.name.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                mission.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.grey400, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${mission.reward} pts',
                    style: const TextStyle(fontSize: 14, color: Colors.amber),
                  ),
                  const SizedBox(width: 16),
                  ...List.generate(
                    mission.difficulty,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.speed,
                        size: 14,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lvl ${mission.difficulty}',
                    style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                  ),
                  const Spacer(),
                  if (mission.visibility == MissionVisibility.private)
                    Icon(Icons.lock, size: 14, color: AppTheme.grey600),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final String teamId;

  const _ActivityTab({required this.teamId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('activity')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppTheme.grey600),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: TextStyle(color: AppTheme.grey600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _ActivityItem(data: data);
          },
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ActivityItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] as Timestamp?;
    final message = data['message'] as String? ?? 'Activity';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 14)),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp.toDate()),
                    style: TextStyle(color: AppTheme.grey600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _TeamSettingsDialog extends StatefulWidget {
  final Team team;
  final TeamRole userRole;

  const _TeamSettingsDialog({required this.team, required this.userRole});

  @override
  State<_TeamSettingsDialog> createState() => _TeamSettingsDialogState();
}

class _TeamSettingsDialogState extends State<_TeamSettingsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    _descriptionController = TextEditingController(
      text: widget.team.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.userRole == TeamRole.owner;

    return AlertDialog(
      title: const Text('Team Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (isOwner) ...[
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _deleteTeam(context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete Team',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _saveChanges(context),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges(BuildContext context) async {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);

    try {
      await teamProvider.updateTeam(
        widget.team.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        context.showSuccess('Team updated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        context.showError('Error: ${e.toString()}');
      }
    }
  }

  void _deleteTeam(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Team'),
        content: const Text(
          'Are you sure you want to archive this team? The team will be hidden but not permanently deleted. Team data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);

      try {
        await teamProvider.deleteTeam(widget.team.id);

        if (context.mounted) {
          Navigator.pop(context); // Close settings dialog
          Navigator.pop(context); // Go back to teams list
          context.showSuccess('Team archived successfully');
        }
      } catch (e) {
        if (context.mounted) {
          context.showError('Failed to archive team');
        }
      }
    }
  }
}
