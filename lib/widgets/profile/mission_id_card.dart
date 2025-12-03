import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';

class MissionIdCard extends StatefulWidget {
  final AppUser user;
  final bool isFlippable;

  const MissionIdCard({super.key, required this.user, this.isFlippable = true});

  @override
  State<MissionIdCard> createState() => _MissionIdCardState();
}

class _MissionIdCardState extends State<MissionIdCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (!widget.isFlippable) return;

    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final isFrontVisible = angle < math.pi / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFrontVisible
                ? _buildFrontCard()
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackCard(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryPurple.withValues(alpha: 0.7),
            const Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -50,
            top: -50,
            child: Icon(
              Icons.stars,
              size: 200,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MISSION ID',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.missionId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.user.role == UserRole.admin ? 'ADMIN' : 'AGENT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // User info
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: widget.user.photoURL != null
                            ? DecorationImage(
                                image: NetworkImage(widget.user.photoURL!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: widget.user.photoURL == null
                            ? Colors.white.withValues(alpha: 0.2)
                            : null,
                      ),
                      child: widget.user.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.white.withValues(alpha: 0.7),
                            )
                          : null,
                    ),

                    const SizedBox(width: 16),

                    // Name and country
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.displayName ??
                                widget.user.username ??
                                widget.user.email.split('@')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.user.username != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@${widget.user.username}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (widget.user.countryCode != null) ...[
                                Text(
                                  _getCountryFlag(widget.user.countryCode!),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                widget.user.country ?? 'Global',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('Level', widget.user.level.toString()),
                    _buildStat(
                      'Missions',
                      widget.user.completedMissions.toString(),
                    ),
                    _buildStat(
                      'Rating',
                      '${widget.user.successRate.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Flip indicator
          if (widget.isFlippable)
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(
                Icons.flip,
                size: 16,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    final joinDate = widget.user.createdAt ?? DateTime.now();
    final rankTitle = AppUser.getRankTitle(widget.user.level);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            AppTheme.primaryPurple.withValues(alpha: 0.7),
            AppTheme.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            left: -50,
            bottom: -50,
            child: Icon(
              Icons.military_tech,
              size: 200,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rankTitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats grid
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBackStat('Join Date', _formatDate(joinDate)),
                      _buildBackStat(
                        'Total Points',
                        '${widget.user.totalPoints} XP',
                      ),
                      _buildBackStat(
                        'Current Streak',
                        '${widget.user.currentStreak} days',
                      ),
                      _buildBackStat(
                        'Best Streak',
                        '${widget.user.bestStreak} days',
                      ),
                      if (widget.user.bio != null)
                        _buildBackStat('Bio', widget.user.bio!, maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Flip indicator
          if (widget.isFlippable)
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(
                Icons.flip,
                size: 16,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBackStat(String label, String value, {int maxLines = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getCountryFlag(String countryCode) {
    // Convert country code to emoji flag
    final codePoints = countryCode.toUpperCase().codeUnits;
    return String.fromCharCodes([
      127397 + codePoints[0],
      127397 + codePoints[1],
    ]);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
