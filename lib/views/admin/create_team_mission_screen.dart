import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/notification_helper.dart';

class CreateTeamMissionScreen extends StatefulWidget {
  final String? teamId;

  const CreateTeamMissionScreen({super.key, this.teamId});

  @override
  State<CreateTeamMissionScreen> createState() =>
      _CreateTeamMissionScreenState();
}

class _CreateTeamMissionScreenState extends State<CreateTeamMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  int reward = 100;
  int difficulty = 1;
  String? selectedTeamId;
  MissionVisibility visibility = MissionVisibility.public;

  @override
  void initState() {
    super.initState();
    selectedTeamId = widget.teamId;
  }

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    // Get teams where user is admin or owner
    final adminTeams = teamProvider.teams
        .where((team) => team.isAdminOrOwner(userId))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      appBar: AppBar(
        title: const Text('Create Team Mission'),
        backgroundColor: AppTheme.grey900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Team Selection
              Card(
                color: AppTheme.grey900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.grey700),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign to Team',
                        style: TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (adminTeams.isEmpty)
                        Text(
                          'You must be an admin of a team to create team missions',
                          style: TextStyle(color: AppTheme.errorRed),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: selectedTeamId,
                          decoration: InputDecoration(
                            hintText: 'Select team',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.grey700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.grey700),
                            ),
                            filled: true,
                            fillColor: AppTheme.grey800,
                          ),
                          dropdownColor: AppTheme.grey800,
                          items: adminTeams.map((team) {
                            return DropdownMenuItem(
                              value: team.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.primaryPurple
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      team.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primaryPurple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(team.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTeamId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a team';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mission Details
              Card(
                color: AppTheme.grey900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.grey700),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission Details',
                        style: TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter mission title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppTheme.grey800,
                        ),
                        onSaved: (v) => title = v ?? '',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe what needs to be done',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppTheme.grey800,
                        ),
                        maxLines: 4,
                        onSaved: (v) => description = v ?? '',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter description' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reward & Difficulty
              Card(
                color: AppTheme.grey900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.grey700),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reward & Difficulty',
                        style: TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: reward.toString(),
                              decoration: InputDecoration(
                                labelText: 'Reward Points',
                                prefixIcon: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: AppTheme.grey800,
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (v) =>
                                  reward = int.tryParse(v ?? '') ?? 100,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter reward'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: difficulty,
                              decoration: InputDecoration(
                                labelText: 'Difficulty',
                                prefixIcon: Icon(
                                  Icons.speed,
                                  color: AppTheme.grey400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: AppTheme.grey800,
                              ),
                              dropdownColor: AppTheme.grey800,
                              items: List.generate(5, (i) => i + 1)
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Row(
                                        children: [
                                          Text('Level $d'),
                                          const SizedBox(width: 4),
                                          ...List.generate(
                                            d,
                                            (i) => Icon(
                                              Icons.star,
                                              size: 12,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => difficulty = v ?? 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visibility
              Card(
                color: AppTheme.grey900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.grey700),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visibility',
                        style: TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<MissionVisibility>(
                        selected: {visibility},
                        onSelectionChanged:
                            (Set<MissionVisibility> newSelection) {
                              setState(() {
                                visibility = newSelection.first;
                              });
                            },
                        segments: const [
                          ButtonSegment(
                            value: MissionVisibility.public,
                            label: Text('Public'),
                            icon: Icon(Icons.public, size: 16),
                          ),
                          ButtonSegment(
                            value: MissionVisibility.private,
                            label: Text('Team Only'),
                            icon: Icon(Icons.lock, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Button
              ElevatedButton(
                onPressed: adminTeams.isEmpty
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();

                          final mission = Mission(
                            id: '',
                            title: title,
                            description: description,
                            reward: reward,
                            difficulty: difficulty,
                            status: MissionStatus.open,
                            createdBy: userId,
                            teamId: selectedTeamId,
                            visibility: visibility,
                          );

                          try {
                            await missionProvider.createMission(mission);

                            // Log activity to team
                            if (selectedTeamId != null) {
                              await FirebaseFirestore.instance
                                  .collection('teams')
                                  .doc(selectedTeamId)
                                  .collection('activity')
                                  .add({
                                    'message': 'New mission created: $title',
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'type': 'mission_created',
                                    'missionId': mission.id,
                                  });
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              context.showSuccess('Team mission created!');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showError('Error: ${e.toString()}');
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Create Team Mission',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
