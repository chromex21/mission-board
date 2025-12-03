import 'package:cloud_firestore/cloud_firestore.dart';

enum MissionStatus { open, assigned, pendingReview, completed }

enum MissionVisibility { public, private }

enum RecurrenceType { none, daily, weekly, monthly }

typedef UserId = String;

typedef MissionId = String;

class Mission {
  final MissionId id;
  final String title;
  final String description;
  final int reward;
  final int difficulty;
  final MissionStatus status;
  final UserId createdBy;
  final UserId? assignedTo;
  final String? teamId;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? proofNote;
  final MissionVisibility visibility;
  final RecurrenceType recurrence;
  final String? templateId;
  final bool isTemplate;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.difficulty,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    this.teamId,
    this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.proofNote,
    this.visibility = MissionVisibility.public,
    this.recurrence = RecurrenceType.none,
    this.templateId,
    this.isTemplate = false,
  });

  factory Mission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mission(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reward: data['reward'] ?? 0,
      difficulty: data['difficulty'] ?? 1,
      status: MissionStatus.values.firstWhere(
        (e) => e.toString() == 'MissionStatus.${data['status'] ?? 'open'}',
        orElse: () => MissionStatus.open,
      ),
      createdBy: data['createdBy'] ?? '',
      assignedTo: data['assignedTo'],
      teamId: data['teamId'],
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null,
      assignedAt: data['assignedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['assignedAt'])
          : null,
      completedAt: data['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt'])
          : null,
      proofNote: data['proofNote'],
      visibility: MissionVisibility.values.firstWhere(
        (e) =>
            e.toString() ==
            'MissionVisibility.${data['visibility'] ?? 'public'}',
        orElse: () => MissionVisibility.public,
      ),
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceType.${data['recurrence'] ?? 'none'}',
        orElse: () => RecurrenceType.none,
      ),
      templateId: data['templateId'],
      isTemplate: data['isTemplate'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'reward': reward,
      'difficulty': difficulty,
      'status': status.name,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'teamId': teamId,
      'createdAt':
          createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'assignedAt': assignedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'proofNote': proofNote,
      'visibility': visibility.name,
      'recurrence': recurrence.name,
      'templateId': templateId,
      'isTemplate': isTemplate,
    };
  }
}
