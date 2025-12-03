import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/mission_model.dart';
import '../../widgets/cards/mission_card.dart';
import '../../routes/app_routes.dart';
import '../../widgets/layout/app_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/activity/activity_feed_widget.dart';

class MissionBoardScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const MissionBoardScreen({super.key, this.onNavigate});

  @override
  State<MissionBoardScreen> createState() => _MissionBoardScreenState();
}

class _MissionBoardScreenState extends State<MissionBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, open, assigned, completed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(MissionProvider provider) async {
    await provider.fetchOpenMissions();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Mission> _filterMissions(List<Mission> missions, String userId) {
    List<Mission> filtered = missions;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((mission) {
        switch (_selectedFilter) {
          case 'open':
            return mission.status == MissionStatus.open;
          case 'assigned':
            return mission.status == MissionStatus.assigned &&
                mission.assignedTo == userId;
          case 'completed':
            return mission.status == MissionStatus.completed;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((mission) {
        return mission.title.toLowerCase().contains(_searchQuery) ||
            mission.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Missions Available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Create your first mission using the + button above'
                  : 'Check back later for new missions',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createMission);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Mission'),
                autofocus: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppTheme.grey600),
            const SizedBox(height: 16),
            Text(
              'No Missions Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No missions match your filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.grey600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedFilter = 'all';
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                side: BorderSide(color: AppTheme.primaryPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final userId = authProvider.user?.uid ?? '';

    return AppLayout(
      currentRoute: '/missions',
      title: 'Missions',
      searchController: _searchController,
      onSearchChanged: _handleSearch,
      onCreateMission: isAdmin
          ? () => Navigator.pushNamed(context, AppRoutes.createMission)
          : null,
      onNavigate: widget.onNavigate ?? (route) {},
      onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      child: missionProvider.isLoading
          ? _buildSkeletonLoader()
          : missionProvider.errorMessage != null
          ? _buildErrorState(
              missionProvider.errorMessage!,
              () => missionProvider.fetchOpenMissions(),
            )
          : Builder(
              builder: (context) {
                final filteredMissions = _filterMissions(
                  missionProvider.missions,
                  userId,
                );

                if (filteredMissions.isEmpty) {
                  return (_searchQuery.isNotEmpty || _selectedFilter != 'all'
                      ? _buildNoResultsState()
                      : _buildEmptyState(isAdmin));
                }

                return Column(
                  children: [
                    // Activity feed widget
                    const ActivityFeedWidget(),

                    // Filter chips with count
                    Container(
                      padding: AppPadding.page(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_searchQuery.isNotEmpty ||
                              _selectedFilter != 'all')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Found ${filteredMissions.length} mission${filteredMissions.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Open', 'open'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Assigned', 'assigned'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Completed', 'completed'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Mission grid
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _handleRefresh(missionProvider),
                        child: _buildMissionGrid(filteredMissions),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppTheme.grey800,
      selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.grey400,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryPurple : AppTheme.grey700,
      ),
    );
  }

  Widget _buildMissionGrid(List<Mission> missions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive columns
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth > 1400) {
          crossAxisCount = 4;
          childAspectRatio = 1.4;
        } else if (constraints.maxWidth > 1000) {
          crossAxisCount = 3;
          childAspectRatio = 1.3;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 2;
          childAspectRatio = 1.4;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 2.5;
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            AppPadding.page(context).left,
            0,
            AppPadding.page(context).right,
            AppPadding.page(context).bottom,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: missions.length,
          itemBuilder: (context, index) {
            final mission = missions[index];
            return MissionCard(mission: mission);
          },
        );
      },
    );
  }
}
