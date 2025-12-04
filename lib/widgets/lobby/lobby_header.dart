import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lobby_model.dart';

/// Live online count header with pulse animation and topic
class LobbyHeader extends StatefulWidget {
  final Lobby lobby;
  final int onlineCount;
  final VoidCallback? onInfoTap;
  final VoidCallback? onUserListTap;

  const LobbyHeader({
    super.key,
    required this.lobby,
    required this.onlineCount,
    this.onInfoTap,
    this.onUserListTap,
  });

  @override
  State<LobbyHeader> createState() => _LobbyHeaderState();
}

class _LobbyHeaderState extends State<LobbyHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        border: Border(bottom: BorderSide(color: AppTheme.grey800, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lobby name and icon
          Row(
            children: [
              if (widget.lobby.iconEmoji != null)
                Text(
                  widget.lobby.iconEmoji!,
                  style: const TextStyle(fontSize: 24),
                ),
              if (widget.lobby.iconEmoji != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lobby.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Topic: ${widget.lobby.topic}',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    ),
                  ],
                ),
              ),

              // Online count with pulse
              InkWell(
                onTap: widget.onUserListTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.successGreen.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.onlineCount} online',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info button
              if (widget.onInfoTap != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onInfoTap,
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.grey400,
                  ),
                  tooltip: 'Lobby Info',
                ),
              ],
            ],
          ),

          // Pinned message
          if (widget.lobby.pinnedMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.infoBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: AppTheme.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.lobby.pinnedMessage!,
                      style: TextStyle(fontSize: 13, color: AppTheme.grey200),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact online indicator (for mobile)
class CompactOnlineIndicator extends StatefulWidget {
  final int onlineCount;
  final VoidCallback? onTap;

  const CompactOnlineIndicator({
    super.key,
    required this.onlineCount,
    this.onTap,
  });

  @override
  State<CompactOnlineIndicator> createState() => _CompactOnlineIndicatorState();
}

class _CompactOnlineIndicatorState extends State<CompactOnlineIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.successGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.onlineCount}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.successGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
