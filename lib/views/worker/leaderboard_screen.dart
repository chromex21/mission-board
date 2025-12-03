import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../widgets/layout/app_layout.dart';
import '../../widgets/dialogs/user_profile_dialog.dart';
import '../../utils/responsive_helper.dart';

class LeaderboardScreen extends StatelessWidget {
  final Function(String)? onNavigate;

  const LeaderboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/leaderboard',
      title: 'Leaderboard',
      onNavigate: onNavigate ?? (route) {},
      onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      child: ResponsiveContent(
        maxWidth: AppSizing.maxContentWidth(context),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('totalPoints', descending: true)
              .limit(50)
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
                      'Loading leaderboard...',
                      style: TextStyle(color: AppTheme.grey400),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Leaderboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.grey400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        snapshot.error.toString(),
                        style: TextStyle(fontSize: 12, color: AppTheme.grey200),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                      ),
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
                    Icon(Icons.leaderboard, size: 64, color: AppTheme.grey600),
                    const SizedBox(height: 16),
                    Text(
                      'No rankings yet',
                      style: TextStyle(fontSize: 16, color: AppTheme.grey400),
                    ),
                  ],
                ),
              );
            }

            final users = snapshot.data!.docs
                .map(
                  (doc) => AppUser.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            return Column(
              children: [
                // Top 3 podium
                if (users.length >= 3) _buildPodium(users.take(3).toList()),

                // Rest of leaderboard
                Expanded(
                  child: Column(
                    children: [
                      if (users.length >= 50)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: AppTheme.infoBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Showing top 50 players',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.infoBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            // StreamBuilder will automatically refresh on pull
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          color: AppTheme.primaryPurple,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppPadding.page(context),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final rank = index + 1;
                              return _LeaderboardCard(user: user, rank: rank);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPodium(List<AppUser> topThree) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.1),
            AppTheme.darkGrey,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1) _buildPodiumPosition(topThree[1], 2, 100),
          if (topThree.isNotEmpty) _buildPodiumPosition(topThree[0], 1, 130),
          if (topThree.length > 2) _buildPodiumPosition(topThree[2], 3, 80),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(AppUser user, int position, double height) {
    final colors = {
      1: AppTheme.primaryPurple,
      2: AppTheme.infoBlue,
      3: AppTheme.successGreen,
    };

    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(medals[position]!, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            user.email.split('@')[0],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, size: 12, color: colors[position]),
              const SizedBox(width: 2),
              Text(
                '${user.totalPoints}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors[position],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: colors[position]!.withValues(alpha: 0.2),
              border: Border.all(color: colors[position]!, width: 2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LVL',
                    style: TextStyle(fontSize: 10, color: AppTheme.grey400),
                  ),
                  Text(
                    '${user.level}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors[position],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final AppUser user;
  final int rank;

  const _LeaderboardCard({required this.user, required this.rank});

  Color _getRankColor() {
    if (rank == 1) return AppTheme.primaryPurple;
    if (rank == 2) return AppTheme.infoBlue;
    if (rank == 3) return AppTheme.successGreen;
    return AppTheme.grey700;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true, // Can dismiss by clicking outside
          builder: (context) => UserProfileDialog(user: user),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.grey900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getRankColor(), width: rank <= 3 ? 2 : 1),
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getRankColor().withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _getRankColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email.split('@')[0],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Lvl ${user.level}',
                        style: TextStyle(fontSize: 11, color: AppTheme.grey400),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: AppTheme.grey600)),
                      const SizedBox(width: 8),
                      Text(
                        AppUser.getRankTitle(user.level),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.totalPoints}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: AppTheme.grey600),
                    const SizedBox(width: 4),
                    Text(
                      '${user.completedMissions} missions',
                      style: TextStyle(fontSize: 11, color: AppTheme.grey400),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
