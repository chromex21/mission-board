import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';

class MissionMarketplaceView extends StatefulWidget {
  const MissionMarketplaceView({super.key});

  @override
  State<MissionMarketplaceView> createState() => _MissionMarketplaceViewState();
}

class _MissionMarketplaceViewState extends State<MissionMarketplaceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionProvider>().fetchMissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey900,
      appBar: AppBar(
        backgroundColor: AppTheme.grey800,
        title: const Text('Mission Marketplace'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.grey400,
          tabs: const [
            Tab(text: 'All Missions'),
            Tab(text: 'My Missions'),
            Tab(text: 'Accepted'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search missions...',
                hintStyle: TextStyle(color: AppTheme.grey600),
                prefixIcon: Icon(Icons.search, color: AppTheme.grey400),
                filled: true,
                fillColor: AppTheme.grey800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.grey700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.grey700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryPurple,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllMissionsTab(searchQuery: _searchQuery),
                _MyMissionsTab(searchQuery: _searchQuery),
                _AcceptedMissionsTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-mission');
        },
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.add),
        label: const Text('Create Mission'),
      ),
    );
  }
}

class _AllMissionsTab extends StatelessWidget {
  final String searchQuery;

  const _AllMissionsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionProvider>(
      builder: (context, missionProvider, child) {
        if (missionProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryPurple),
          );
        }

        final openMissions = missionProvider.missions
            .where((m) => m.status == MissionStatus.open)
            .where(
              (m) =>
                  searchQuery.isEmpty ||
                  m.title.toLowerCase().contains(searchQuery) ||
                  m.description.toLowerCase().contains(searchQuery),
            )
            .toList();

        if (openMissions.isEmpty) {
          return _EmptyState(
            icon: Icons.work_outline,
            message: searchQuery.isEmpty
                ? 'No available missions'
                : 'No missions match your search',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await missionProvider.fetchMissions();
          },
          color: AppTheme.primaryPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: openMissions.length,
            itemBuilder: (context, index) {
              return _MissionCard(mission: openMissions[index]);
            },
          ),
        );
      },
    );
  }
}

class _MyMissionsTab extends StatelessWidget {
  final String searchQuery;

  const _MyMissionsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.uid ?? '';

    return Consumer<MissionProvider>(
      builder: (context, missionProvider, child) {
        if (missionProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryPurple),
          );
        }

        final myMissions = missionProvider.missions
            .where((m) => m.createdBy == currentUserId)
            .where(
              (m) =>
                  searchQuery.isEmpty ||
                  m.title.toLowerCase().contains(searchQuery) ||
                  m.description.toLowerCase().contains(searchQuery),
            )
            .toList();

        if (myMissions.isEmpty) {
          return _EmptyState(
            icon: Icons.create_new_folder_outlined,
            message: searchQuery.isEmpty
                ? 'You haven\'t created any missions'
                : 'No missions match your search',
            action: searchQuery.isEmpty
                ? TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-mission');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Mission'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                    ),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await missionProvider.fetchMissions();
          },
          color: AppTheme.primaryPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myMissions.length,
            itemBuilder: (context, index) {
              return _MissionCard(
                mission: myMissions[index],
                isOwnMission: true,
              );
            },
          ),
        );
      },
    );
  }
}

class _AcceptedMissionsTab extends StatelessWidget {
  final String searchQuery;

  const _AcceptedMissionsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.uid ?? '';

    return Consumer<MissionProvider>(
      builder: (context, missionProvider, child) {
        if (missionProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryPurple),
          );
        }

        final acceptedMissions = missionProvider.missions
            .where((m) => m.assignedTo == currentUserId)
            .where(
              (m) =>
                  searchQuery.isEmpty ||
                  m.title.toLowerCase().contains(searchQuery) ||
                  m.description.toLowerCase().contains(searchQuery),
            )
            .toList();

        if (acceptedMissions.isEmpty) {
          return _EmptyState(
            icon: Icons.assignment_outlined,
            message: searchQuery.isEmpty
                ? 'You haven\'t accepted any missions'
                : 'No missions match your search',
            action: searchQuery.isEmpty
                ? TextButton.icon(
                    onPressed: () {
                      // Switch to All Missions tab
                      DefaultTabController.of(context).animateTo(0);
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Browse Missions'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                    ),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await missionProvider.fetchMissions();
          },
          color: AppTheme.primaryPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: acceptedMissions.length,
            itemBuilder: (context, index) {
              return _MissionCard(
                mission: acceptedMissions[index],
                isAccepted: true,
              );
            },
          ),
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final bool isOwnMission;
  final bool isAccepted;

  const _MissionCard({
    required this.mission,
    this.isOwnMission = false,
    this.isAccepted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.grey800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/mission-details',
            arguments: mission.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: mission.status),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                mission.description,
                style: TextStyle(color: AppTheme.grey400, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _MissionStat(
                    icon: Icons.monetization_on,
                    label: '${mission.reward} pts',
                    color: AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 16),
                  _MissionStat(
                    icon: Icons.star,
                    label: 'Level ${mission.difficulty}',
                    color: AppTheme.infoBlue,
                  ),
                  const Spacer(),
                  if (!isOwnMission &&
                      !isAccepted &&
                      mission.status == MissionStatus.open)
                    ElevatedButton(
                      onPressed: () {
                        _acceptMission(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (mission.status) {
      case MissionStatus.open:
        return AppTheme.successGreen;
      case MissionStatus.assigned:
        return AppTheme.infoBlue;
      case MissionStatus.pendingReview:
        return AppTheme.warningOrange;
      case MissionStatus.completed:
        return AppTheme.grey600;
    }
  }

  void _acceptMission(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.uid ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: const Text(
          'Accept Mission?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to accept "${mission.title}"?',
          style: TextStyle(color: AppTheme.grey200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.grey400)),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<MissionProvider>().acceptMission(
                mission.id,
                currentUserId,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Mission accepted!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MissionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case MissionStatus.open:
        color = AppTheme.successGreen;
        label = 'OPEN';
        break;
      case MissionStatus.assigned:
        color = AppTheme.infoBlue;
        label = 'ASSIGNED';
        break;
      case MissionStatus.pendingReview:
        color = AppTheme.warningOrange;
        label = 'PENDING';
        break;
      case MissionStatus.completed:
        color = AppTheme.grey600;
        label = 'COMPLETED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MissionStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MissionStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _EmptyState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.grey600),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.grey400, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}
