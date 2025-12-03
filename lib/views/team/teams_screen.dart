import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/team_model.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/notification_helper.dart';
import '../../utils/responsive_helper.dart';

class TeamsScreen extends StatelessWidget {
  final Function(String)? onNavigate;

  const TeamsScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    final userTeams = teamProvider.getUserTeams(userId);

    return AppLayout(
      currentRoute: '/teams',
      title: 'Teams',
      onNavigate: onNavigate ?? (route) {},
      onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      child: Stack(
        children: [
          teamProvider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading teams...',
                        style: TextStyle(color: AppTheme.grey400),
                      ),
                    ],
                  ),
                )
              : userTeams.isEmpty
              ? _buildEmptyState(context)
              : ResponsiveContent(
                  maxWidth: AppSizing.maxContentWidth(context),
                  child: ResponsiveGrid(
                    padding: AppPadding.page(context),
                    itemCount: userTeams.length,
                    itemBuilder: (context, index) {
                      final team = userTeams[index];
                      return _TeamCard(team: team, userId: userId);
                    },
                  ),
                ),
          // Only admins can create teams
          if (authProvider.isAdmin)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => _showCreateTeamDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Team'),
                backgroundColor: AppTheme.primaryPurple,
                tooltip: 'Create a new team',
                heroTag: 'create_team',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 80, color: AppTheme.grey600),
          const SizedBox(height: 16),
          Text(
            'No teams yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            authProvider.isAdmin
                ? 'Create a team to collaborate with others'
                : 'Ask an admin to add you to a team',
            style: TextStyle(fontSize: 14, color: AppTheme.grey600),
            textAlign: TextAlign.center,
          ),
          if (authProvider.isAdmin) ...[
            const SizedBox(height: 4),
            Text(
              'Use the + button below to get started',
              style: TextStyle(fontSize: 12, color: AppTheme.grey700),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: const Text('Create Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'e.g., Design Squad',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What does your team do?',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final teamProvider = Provider.of<TeamProvider>(
                context,
                listen: false,
              );

              final team = await teamProvider.createTeam(
                name: nameController.text.trim(),
                ownerId: authProvider.user?.uid ?? '',
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (team != null) {
                  context.showSuccess('Team "${team.name}" created!');
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final String userId;

  const _TeamCard({required this.team, required this.userId});

  @override
  Widget build(BuildContext context) {
    final role = team.getUserRole(userId);
    final roleColor = role == TeamRole.owner
        ? AppTheme.primaryPurple
        : role == TeamRole.admin
        ? AppTheme.infoBlue
        : AppTheme.grey400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/team/${team.id}', arguments: team.id);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        team.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                role.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.people,
                              size: 12,
                              color: AppTheme.grey400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${team.totalMembers}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button ONLY for team owners (not regular members)
                  if (role == TeamRole.owner)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppTheme.errorRed,
                      ),
                      onPressed: () => _showDeleteDialog(context, team),
                      tooltip: 'Delete Team',
                    ),
                  Icon(Icons.chevron_right, size: 20, color: AppTheme.grey600),
                ],
              ),
              if (team.description != null && team.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  team.description!,
                  style: TextStyle(fontSize: 13, color: AppTheme.grey400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: const Text('Delete Team?'),
        content: Text(
          'Are you sure you want to delete "${team.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final teamProvider = Provider.of<TeamProvider>(
                context,
                listen: false,
              );
              try {
                await teamProvider.deleteTeam(team.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Team "${team.name}" deleted'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
