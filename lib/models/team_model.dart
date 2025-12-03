import 'package:cloud_firestore/cloud_firestore.dart';

enum TeamRole { owner, admin, member }

class Team {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.ownerId,
    List<String>? adminIds,
    List<String>? memberIds,
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
  }) : adminIds = adminIds ?? [],
       memberIds = memberIds ?? [],
       createdAt = createdAt ?? DateTime.now();

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      ownerId: data['ownerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  TeamRole getUserRole(String userId) {
    if (userId == ownerId) return TeamRole.owner;
    if (adminIds.contains(userId)) return TeamRole.admin;
    if (memberIds.contains(userId)) return TeamRole.member;
    return TeamRole.member;
  }

  List<String> get allMemberIds => [ownerId, ...adminIds, ...memberIds];

  int get totalMembers => allMemberIds.toSet().length;

  bool isMember(String userId) => allMemberIds.contains(userId);

  bool isAdminOrOwner(String userId) =>
      userId == ownerId || adminIds.contains(userId);
}

class MissionComment {
  final String id;
  final String missionId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachments;
  final List<String> mentions;
  final bool isSystemMessage;

  MissionComment({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.content,
    DateTime? createdAt,
    this.updatedAt,
    List<String>? attachments,
    List<String>? mentions,
    this.isSystemMessage = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       attachments = attachments ?? [],
       mentions = mentions ?? [];

  factory MissionComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionComment(
      id: doc.id,
      missionId: data['missionId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : null,
      attachments: List<String>.from(data['attachments'] ?? []),
      mentions: List<String>.from(data['mentions'] ?? []),
      isSystemMessage: data['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'attachments': attachments,
      'mentions': mentions,
      'isSystemMessage': isSystemMessage,
    };
  }

  factory MissionComment.systemMessage(String missionId, String content) {
    return MissionComment(
      id: '',
      missionId: missionId,
      userId: 'system',
      content: content,
      isSystemMessage: true,
    );
  }
}
