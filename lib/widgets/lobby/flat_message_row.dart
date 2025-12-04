import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lobby_message_model.dart';
import '../../core/theme/app_theme.dart';

/// Flat terminal-style message row (no bubbles)
/// Optimized for speed and scanning
class FlatMessageRow extends StatelessWidget {
  final LobbyMessage message;
  final bool isOwnMessage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReaction;

  const FlatMessageRow({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onTap,
    this.onLongPress,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _buildSystemMessage();
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? AppTheme.primaryPurple.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            left: isOwnMessage
                ? BorderSide(color: AppTheme.primaryPurple, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.grey600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 12),

            // User rank badge
            if (message.userRank != null) _buildRankBadge(message.userRank!),

            // Username
            Text(
              '[${message.userName}]',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _getUserColor(message.userId),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),

            // Message content
            Expanded(child: _buildMessageContent()),

            // Reactions (compact)
            if (message.reactions != null && message.reactions!.isNotEmpty)
              _buildCompactReactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(String rank) {
    final emoji = _getRankEmoji(rank);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  String _getRankEmoji(String rank) {
    switch (rank) {
      case 'admin':
        return '👑';
      case 'mod':
        return '🛡️';
      case 'og':
        return '⭐';
      case 'member':
        return '✅';
      case 'guest':
        return '👋';
      default:
        return '';
    }
  }

  Widget _buildMessageContent() {
    switch (message.messageType) {
      case 'voice':
        return Row(
          children: [
            Icon(Icons.mic, size: 14, color: AppTheme.primaryPurple),
            const SizedBox(width: 4),
            Text(
              'Voice ${message.voiceDuration}s',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryPurple,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );

      case 'image':
      case 'gif':
        return Row(
          children: [
            Icon(Icons.image, size: 14, color: AppTheme.infoBlue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

      case 'text':
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    // Highlight mentions
    final parts = message.content.split(' ');
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
        children: parts.map((part) {
          if (part.startsWith('@')) {
            return TextSpan(
              text: '$part ',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          return TextSpan(text: '$part ');
        }).toList(),
      ),
    );
  }

  Widget _buildCompactReactions() {
    final reactions = message.reactions!;
    final firstReaction = reactions.entries.first;
    final totalReactions = reactions.values.fold<int>(
      0,
      (sum, users) => sum + users.length,
    );

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.grey800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(firstReaction.key, style: const TextStyle(fontSize: 12)),
          if (totalReactions > 1) ...[
            const SizedBox(width: 2),
            Text(
              totalReactions.toString(),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.grey400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    IconData icon;
    Color iconColor;

    switch (message.systemType) {
      case 'join':
        icon = Icons.login;
        iconColor = AppTheme.successGreen;
        break;
      case 'leave':
        icon = Icons.logout;
        iconColor = AppTheme.grey600;
        break;
      case 'welcome':
        icon = Icons.waving_hand;
        iconColor = AppTheme.warningOrange;
        break;
      case 'pin':
        icon = Icons.push_pin;
        iconColor = AppTheme.infoBlue;
        break;
      case 'rank_change':
        icon = Icons.star;
        iconColor = AppTheme.primaryPurple;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = AppTheme.grey600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Text(
            '${_formatTime(message.createdAt)} • ',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.grey600,
              fontFamily: 'monospace',
            ),
          ),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Color _getUserColor(String userId) {
    // Generate consistent color per user
    final hash = userId.hashCode;
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.successGreen,
      AppTheme.infoBlue,
      AppTheme.warningOrange,
      const Color(0xFF10B981), // emerald
      const Color(0xFF8B5CF6), // violet
      const Color(0xFFEC4899), // pink
      const Color(0xFFF59E0B), // amber
    ];

    return colors[hash.abs() % colors.length];
  }
}
