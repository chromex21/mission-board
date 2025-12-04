import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';

enum CardStyle { gradient, solid, minimal }

class MissionIdCard extends StatefulWidget {
  final AppUser user;
  final bool isFlippable;
  final CardStyle cardStyle;

  const MissionIdCard({
    super.key,
    required this.user,
    this.isFlippable = true,
    this.cardStyle = CardStyle.gradient,
  });

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
    final isAdmin = widget.user.role == UserRole.admin;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: _getFrontGradient(isAdmin),
        borderRadius: BorderRadius.circular(16),
        border: isAdmin
            ? Border.all(
                color: AppTheme.warningOrange.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (isAdmin ? AppTheme.warningOrange : AppTheme.primaryPurple)
                .withValues(alpha: 0.3),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
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

                const SizedBox(height: 6),

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
    final isAdmin = widget.user.role == UserRole.admin;

    // Generate user profile URL for QR code
    final profileData = 'mission-board://user/${widget.user.uid}';

    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: _getBackGradient(isAdmin),
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
            left: -30,
            bottom: -30,
            child: Icon(
              isAdmin ? Icons.shield : Icons.military_tech,
              size: 160,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - QR Code
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              rankTitle.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warningOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: profileData,
                          version: QrVersions.auto,
                          size: 80,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Scan to connect',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right side - Stats
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactStat('Joined', _formatDate(joinDate)),
                          const SizedBox(height: 10),
                          _buildCompactStat(
                            'Total XP',
                            widget.user.totalPoints.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildCompactStat(
                            'Missions',
                            widget.user.completedMissions.toString(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactStat(
                                  'Streak',
                                  '${widget.user.currentStreak}d',
                                ),
                              ),
                              Expanded(
                                child: _buildCompactStat(
                                  'Best',
                                  '${widget.user.bestStreak}d',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Verification badge
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Agent',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
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

          // Flip indicator
          if (widget.isFlippable)
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(
                Icons.flip,
                size: 14,
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

  Widget _buildCompactStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  LinearGradient _getFrontGradient(bool isAdmin) {
    if (isAdmin) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.warningOrange,
          AppTheme.warningOrange.withValues(alpha: 0.7),
          const Color(0xFF1A1A2E),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.primaryPurple,
        AppTheme.primaryPurple.withValues(alpha: 0.7),
        const Color(0xFF1A1A2E),
      ],
    );
  }

  LinearGradient _getBackGradient(bool isAdmin) {
    if (isAdmin) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1A1A2E),
          AppTheme.warningOrange.withValues(alpha: 0.6),
          AppTheme.warningOrange,
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1A1A2E),
        AppTheme.primaryPurple.withValues(alpha: 0.7),
        AppTheme.primaryPurple,
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
