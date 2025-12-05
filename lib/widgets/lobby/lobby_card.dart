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
    required this.isJoined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey700),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildActivityIndicator(),
                    ],
                  ),
                ),
                if (isJoined)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.15),
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

            // Stats row (wrap to avoid overflow on narrow widths)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStat(
                  Icons.circle,
                  '${lobby.onlineCount} online',
                  AppTheme.successGreen,
                ),
                _buildStat(
                  Icons.people,
                  '${lobby.totalMembers} members',
                  AppTheme.grey400,
                ),
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
                              Icon(Icons.login, size: 16, color: Colors.white),
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
    );
  }

  Widget _buildActivityIndicator() {
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
      mainAxisSize: MainAxisSize.min,
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
