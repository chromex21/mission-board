import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/responsive_helper.dart';

class MissionsDashboardView extends StatefulWidget {
  final Function(String)? onNavigate;

  const MissionsDashboardView({super.key, this.onNavigate});

  @override
  State<MissionsDashboardView> createState() => _MissionsDashboardViewState();
}

class _MissionsDashboardViewState extends State<MissionsDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs now
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
    return AppLayout(
      currentRoute: '/missions',
      title: 'Missions',
      onNavigate: widget.onNavigate ?? (route) {},
      child: Stack(
        children: [
          Column(
            children: [
              // Tabs
              Container(
                color: Theme.of(context).cardColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).textTheme.bodyLarge?.color,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color,
                  tabs: const [
                    Tab(text: 'Browse'),
                    Tab(text: 'My Missions'),
                    Tab(text: 'Accepted'),
                    Tab(text: 'Create'),
                  ],
                ),
              ),
              // Search bar
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: AppSizing.maxContentWidth(context),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search missions...',
                      hintStyle: Theme.of(
                        context,
                      ).inputDecorationTheme.hintStyle,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
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
                    const _CreateMissionTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
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
          color: Theme.of(context).colorScheme.primary,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: AppSizing.maxContentWidth(context),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: openMissions.length,
                itemBuilder: (context, index) {
                  return _MissionCard(mission: openMissions[index]);
                },
              ),
            ),
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
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
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await missionProvider.fetchMissions();
          },
          color: Theme.of(context).colorScheme.primary,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: AppSizing.maxContentWidth(context),
              ),
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
            ),
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
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
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await missionProvider.fetchMissions();
          },
          color: Theme.of(context).colorScheme.primary,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: AppSizing.maxContentWidth(context),
              ),
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
            ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
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
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Accept Mission?',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Do you want to accept "${mission.title}"?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

// Embedded Create Mission Tab
class _CreateMissionTab extends StatefulWidget {
  const _CreateMissionTab();

  @override
  State<_CreateMissionTab> createState() => _CreateMissionTabState();
}

class _CreateMissionTabState extends State<_CreateMissionTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();

  int _difficulty = 1;
  MissionVisibility _visibility = MissionVisibility.public;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: AppSizing.maxContentWidth(context),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Mission',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Mission Title',
                    hintText: 'Enter a clear mission title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe what needs to be done...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reward field
                TextFormField(
                  controller: _rewardController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Reward (Points)',
                    hintText: '100',
                    prefixIcon: Icon(
                      Icons.monetization_on,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reward amount';
                    }
                    final reward = int.tryParse(value);
                    if (reward == null || reward <= 0) {
                      return 'Please enter a valid reward amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Difficulty slider
                Text(
                  'Difficulty Level: $_difficulty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _difficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() => _difficulty = value.toInt());
                  },
                ),
                const SizedBox(height: 16),

                // Visibility toggle
                Text(
                  'Visibility',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(
                          () => _visibility = MissionVisibility.public,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _visibility == MissionVisibility.public
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _visibility == MissionVisibility.public
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _visibility == MissionVisibility.public
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _visibility == MissionVisibility.public
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 8),
                              const Text('Public'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(
                          () => _visibility = MissionVisibility.private,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _visibility == MissionVisibility.private
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _visibility == MissionVisibility.private
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _visibility == MissionVisibility.private
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _visibility == MissionVisibility.private
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 8),
                              const Text('Private'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createMission,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Mission'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createMission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('You must be logged in to create a mission');
      }

      final mission = Mission(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        reward: int.parse(_rewardController.text),
        difficulty: _difficulty,
        status: MissionStatus.open,
        createdBy: currentUser.uid,
        visibility: _visibility,
        createdAt: DateTime.now(),
      );

      await context.read<MissionProvider>().createMission(
        mission,
        userName: currentUser.displayName ?? 'Anonymous',
        userPhotoUrl: currentUser.photoURL,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mission created successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _rewardController.clear();
        setState(() {
          _difficulty = 1;
          _visibility = MissionVisibility.public;
        });
        // Switch to My Missions tab
        DefaultTabController.of(context).animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
