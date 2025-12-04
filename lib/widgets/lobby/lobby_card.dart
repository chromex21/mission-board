import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lobby_model.dart';

/// Lobby discovery card for browsing/joining lobbies
class LobbyCard extends StatelessWidget {
  final Lobby lobby;
  final VoidCallback onJoin;
  final bool isJoined;

  const LobbyCard({
    super.key,
    required this.lobby,
    required this.onJoin,
    this.isJoined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.grey900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isJoined
              ? AppTheme.primaryPurple.withValues(alpha: 0.5)
              : AppTheme.grey800,
          width: isJoined ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and status
              Row(
                children: [
                  // Icon
                  if (lobby.iconEmoji != null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          lobby.iconEmoji!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  if (lobby.iconEmoji != null) const SizedBox(width: 12),

                  // Name and activity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lobby.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildActivityIndicator(),
                      ],
                    ),
                  ),

                  // Join status badge
                  if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.successGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'JOINED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                lobby.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey200,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  // Online count
                  _buildStat(
                    Icons.circle,
                    '${lobby.onlineCount} online',
                    AppTheme.successGreen,
                  ),
                  const SizedBox(width: 16),

                  // Total members
                  _buildStat(
                    Icons.people,
                    '${lobby.totalMembers} members',
                    AppTheme.grey400,
                  ),

                  const Spacer(),

                  // Join button
                  if (!isJoined)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryPurple,
                            AppTheme.primaryPurple.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onJoin,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.login,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'JOIN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIndicator() {
    // Determine activity level based on online count
    final isActive = lobby.onlineCount >= 5;
    final activityText = isActive ? 'active now' : 'quiet';
    final activityColor = isActive ? AppTheme.successGreen : AppTheme.grey600;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: activityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          activityText,
          style: TextStyle(
            fontSize: 12,
            color: activityColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Grid of lobby cards for discovery
class LobbyGrid extends StatelessWidget {
  final List<Lobby> lobbies;
  final Function(Lobby) onJoinLobby;
  final Set<String> joinedLobbyIds;

  const LobbyGrid({
    super.key,
    required this.lobbies,
    required this.onJoinLobby,
    this.joinedLobbyIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: lobbies.length,
      itemBuilder: (context, index) {
        final lobby = lobbies[index];
        return LobbyCard(
          lobby: lobby,
          onJoin: () => onJoinLobby(lobby),
          isJoined: joinedLobbyIds.contains(lobby.id),
        );
      },
    );
  }
}
