import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/responsive_container.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  int reward = 0;
  int difficulty = 1;

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Mission')),
      body: ResponsiveFormContainer(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Complete daily workout',
                    helperText: 'Short, clear mission title',
                  ),
                  onSaved: (v) => title = v ?? '',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What needs to be accomplished?',
                    helperText: 'Be specific about requirements',
                  ),
                  maxLines: 3,
                  onSaved: (v) => description = v ?? '',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Reward Points',
                    hintText: '100',
                    helperText:
                        'Suggested: Easy (50-100), Medium (100-200), Hard (200+)',
                    prefixIcon: Icon(Icons.stars_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: '100',
                  onSaved: (v) => reward = int.tryParse(v ?? '') ?? 100,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter reward points';
                    final val = int.tryParse(v);
                    if (val == null || val < 10) return 'Minimum 10 points';
                    if (val > 1000) return 'Maximum 1000 points';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: difficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty Level',
                    helperText: 'How challenging is this mission?',
                  ),
                  items: [
                    const DropdownMenuItem(value: 1, child: Text('⭐ Easy (1)')),
                    const DropdownMenuItem(
                      value: 2,
                      child: Text('⭐⭐ Medium (2)'),
                    ),
                    const DropdownMenuItem(
                      value: 3,
                      child: Text('⭐⭐⭐ Challenging (3)'),
                    ),
                    const DropdownMenuItem(
                      value: 4,
                      child: Text('⭐⭐⭐⭐ Hard (4)'),
                    ),
                    const DropdownMenuItem(
                      value: 5,
                      child: Text('⭐⭐⭐⭐⭐ Expert (5)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => difficulty = v ?? 1),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      final navigator = Navigator.of(context);
                      final mission = Mission(
                        id: '',
                        title: title,
                        description: description,
                        reward: reward,
                        difficulty: difficulty,
                        status: MissionStatus.open,
                        createdBy: authProvider.user?.uid ?? '',
                        assignedTo: null,
                      );
                      await missionProvider.createMission(mission);
                      navigator.pop();
                    }
                  },
                  child: const Text('Create Mission'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
