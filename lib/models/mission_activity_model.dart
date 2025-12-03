import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  missionCompleted,
  missionCreated,
  missionAccepted,
  paymentReceived,
  levelUp,
  milestoneReached,
  teamJoined,
}

class MissionActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final ActivityType type;
  final DateTime timestamp;
  final Map<String, dynamic> data; // Flexible data for different activity types
  final List<String> likedBy;
  final int commentCount;

  MissionActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    required this.timestamp,
    required this.data,
    this.likedBy = const [],
    this.commentCount = 0,
  });

  factory MissionActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${data['type']}',
        orElse: () => ActivityType.missionCompleted,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
      'likedBy': likedBy,
      'commentCount': commentCount,
    };
  }

  // Helper methods to create specific activity types
  static MissionActivity missionCompleted({
    required String userId,
    required String userName,
    String? userAvatar,
    required String missionTitle,
    required int reward,
    required int difficulty,
  }) {
    return MissionActivity(
      id: '',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      type: ActivityType.missionCompleted,
      timestamp: DateTime.now(),
      data: {
        'missionTitle': missionTitle,
        'reward': reward,
        'difficulty': difficulty,
      },
    );
  }

  static MissionActivity paymentReceived({
    required String userId,
    required String userName,
    String? userAvatar,
    required int amount,
    required String missionTitle,
  }) {
    return MissionActivity(
      id: '',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      type: ActivityType.paymentReceived,
      timestamp: DateTime.now(),
      data: {'amount': amount, 'missionTitle': missionTitle},
    );
  }

  static MissionActivity levelUp({
    required String userId,
    required String userName,
    String? userAvatar,
    required int newLevel,
    required int totalXP,
  }) {
    return MissionActivity(
      id: '',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      type: ActivityType.levelUp,
      timestamp: DateTime.now(),
      data: {'newLevel': newLevel, 'totalXP': totalXP},
    );
  }

  static MissionActivity milestoneReached({
    required String userId,
    required String userName,
    String? userAvatar,
    required String milestone,
    required int count,
  }) {
    return MissionActivity(
      id: '',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      type: ActivityType.milestoneReached,
      timestamp: DateTime.now(),
      data: {'milestone': milestone, 'count': count},
    );
  }
}
