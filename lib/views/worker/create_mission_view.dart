import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';

class CreateMissionView extends StatefulWidget {
  const CreateMissionView({super.key});

  @override
  State<CreateMissionView> createState() => _CreateMissionViewState();
}

class _CreateMissionViewState extends State<CreateMissionView> {
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
    return Scaffold(
      backgroundColor: AppTheme.grey900,
      appBar: AppBar(
        backgroundColor: AppTheme.grey800,
        title: const Text('Create Mission'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              _buildSectionTitle('Mission Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter a clear mission title',
                  hintStyle: TextStyle(color: AppTheme.grey600),
                  filled: true,
                  fillColor: AppTheme.grey800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.grey700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.grey700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryPurple,
                      width: 2,
                    ),
                  ),
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
              const SizedBox(height: 24),

              // Description field
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe what needs to be done...',
                  hintStyle: TextStyle(color: AppTheme.grey600),
                  filled: true,
                  fillColor: AppTheme.grey800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.grey700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.grey700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryPurple,
                      width: 2,
                    ),
                  ),
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
              const SizedBox(height: 24),

              // Reward field
              _buildSectionTitle('Reward (Points)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rewardController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '100',
                  hintStyle: TextStyle(color: AppTheme.grey600),
                  prefixIcon: Icon(
                    Icons.monetization_on,
                    color: AppTheme.warningOrange,
                  ),
                  filled: true,
                  fillColor: AppTheme.grey800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.grey700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.grey700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryPurple,
                      width: 2,
                    ),
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
              _buildSectionTitle('Difficulty Level'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.grey800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.grey700),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level $_difficulty',
                          style: TextStyle(
                            color: _getDifficultyColor(),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < _difficulty
                                  ? Icons.star
                                  : Icons.star_border,
                              color: _getDifficultyColor(),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: _getDifficultyColor(),
                      inactiveColor: AppTheme.grey700,
                      onChanged: (value) {
                        setState(() => _difficulty = value.toInt());
                      },
                    ),
                    Text(
                      _getDifficultyLabel(),
                      style: TextStyle(color: AppTheme.grey400, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Visibility toggle
              _buildSectionTitle('Visibility'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.grey800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.grey700),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _VisibilityButton(
                        label: 'Public',
                        icon: Icons.public,
                        isSelected: _visibility == MissionVisibility.public,
                        onTap: () => setState(
                          () => _visibility = MissionVisibility.public,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _VisibilityButton(
                        label: 'Private',
                        icon: Icons.lock,
                        isSelected: _visibility == MissionVisibility.private,
                        onTap: () => setState(
                          () => _visibility = MissionVisibility.private,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    disabledBackgroundColor: AppTheme.grey700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Mission',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (_difficulty) {
      case 1:
        return AppTheme.successGreen;
      case 2:
        return AppTheme.infoBlue;
      case 3:
        return AppTheme.warningOrange;
      case 4:
        return Colors.orange;
      case 5:
        return AppTheme.errorRed;
      default:
        return AppTheme.grey400;
    }
  }

  String _getDifficultyLabel() {
    switch (_difficulty) {
      case 1:
        return 'Very Easy - Quick tasks';
      case 2:
        return 'Easy - Simple tasks';
      case 3:
        return 'Medium - Moderate effort';
      case 4:
        return 'Hard - Requires skill';
      case 5:
        return 'Expert - Challenging tasks';
      default:
        return '';
    }
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
        id: '', // Firestore will generate
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
          );      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mission created successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
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

class _VisibilityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: AppTheme.primaryPurple, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryPurple : AppTheme.grey400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryPurple : AppTheme.grey400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
