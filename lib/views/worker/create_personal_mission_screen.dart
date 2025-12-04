import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/mission_model.dart';
import '../../models/mission_templates.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/responsive_container.dart';
import '../../utils/notification_helper.dart';

class CreatePersonalMissionScreen extends StatefulWidget {
  const CreatePersonalMissionScreen({super.key});

  @override
  State<CreatePersonalMissionScreen> createState() =>
      _CreatePersonalMissionScreenState();
}

class _CreatePersonalMissionScreenState
    extends State<CreatePersonalMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  int reward = 10;
  int difficulty = 1;
  MissionVisibility visibility = MissionVisibility.private;
  RecurrenceType recurrence = RecurrenceType.none;
  MissionTemplate? selectedTemplate;
  bool showTemplates = true;

  void _applyTemplate(MissionTemplate template) {
    setState(() {
      selectedTemplate = template;
      title = template.title;
      description = template.description;
      reward = template.reward;
      difficulty = template.difficulty;
      showTemplates = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      appBar: AppBar(
        title: const Text('Create Personal Mission'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                showTemplates = !showTemplates;
              });
            },
            icon: Icon(showTemplates ? Icons.edit : Icons.grid_view, size: 18),
            label: Text(showTemplates ? 'Custom' : 'Templates'),
          ),
        ],
      ),
      body: showTemplates
          ? _buildTemplatesView()
          : _buildCustomForm(missionProvider, authProvider),
    );
  }

  Widget _buildTemplatesView() {
    final categories = MissionTemplates.categories;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ResponsiveContentContainer(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final templates = MissionTemplates.getByCategory(category);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                  ...templates.map(
                    (template) => _TemplateCard(
                      template: template,
                      onTap: () => _applyTemplate(template),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomForm(
    MissionProvider missionProvider,
    AuthProvider authProvider,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ResponsiveFormContainer(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedTemplate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            selectedTemplate!.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Using template: ${selectedTemplate!.title}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                selectedTemplate = null;
                                title = '';
                                description = '';
                                reward = 10;
                                difficulty = 1;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What do you want to accomplish?',
                    ),
                    onSaved: (v) => title = v ?? '',
                    onChanged: (v) => title = v,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details about this mission',
                    ),
                    maxLines: 3,
                    onSaved: (v) => description = v ?? '',
                    onChanged: (v) => description = v,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: reward.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Reward Points',
                            prefixIcon: Icon(Icons.stars_rounded, size: 20),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => reward = int.tryParse(v ?? '') ?? 10,
                          onChanged: (v) => reward = int.tryParse(v) ?? reward,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter reward' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: difficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            prefixIcon: Icon(
                              Icons.signal_cellular_alt,
                              size: 20,
                            ),
                          ),
                          items: List.generate(5, (i) => i + 1)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('Level $d'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => difficulty = v ?? 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grey400,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.grey900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.grey700),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Visibility'),
                          subtitle: Text(
                            visibility == MissionVisibility.private
                                ? 'Only you can see this'
                                : 'Visible to everyone',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grey400,
                            ),
                          ),
                          trailing: Switch(
                            value: visibility == MissionVisibility.public,
                            onChanged: (v) {
                              setState(() {
                                visibility = v
                                    ? MissionVisibility.public
                                    : MissionVisibility.private;
                              });
                            },
                            activeThumbColor: AppTheme.primaryPurple,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.grey700),
                        ListTile(
                          title: const Text('Recurrence'),
                          subtitle: Text(
                            _getRecurrenceLabel(recurrence),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grey400,
                            ),
                          ),
                          trailing: DropdownButton<RecurrenceType>(
                            value: recurrence,
                            underline: const SizedBox(),
                            dropdownColor: AppTheme.grey800,
                            items: RecurrenceType.values
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(_getRecurrenceLabel(r)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                recurrence = v ?? RecurrenceType.none;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();

                        final mission = Mission(
                          id: '',
                          title: title,
                          description: description,
                          reward: reward,
                          difficulty: difficulty,
                          status: MissionStatus.open,
                          createdBy: authProvider.user?.uid ?? '',
                          assignedTo: authProvider
                              .user
                              ?.uid, // Auto-assign personal missions
                          visibility: visibility,
                          recurrence: recurrence,
                          templateId: selectedTemplate?.id,
                          createdAt: DateTime.now(),
                        );

                        try {
                          await missionProvider.createMission(mission);
                          if (mounted) {
                            Navigator.pop(context);
                            context.showSuccess('Personal mission created!');
                          }
                        } catch (e) {
                          if (mounted) {
                            context.showError('Error: ${e.toString()}');
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Mission'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One-time';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final MissionTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    template.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 12,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${template.reward}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grey200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lvl ${template.difficulty}',
                    style: TextStyle(fontSize: 11, color: AppTheme.grey600),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: AppTheme.grey600),
            ],
          ),
        ),
      ),
    );
  }
}
