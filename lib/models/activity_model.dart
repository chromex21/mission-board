import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  missionCreated,
  missionAccepted,
  missionCompleted,
  teamCreated,
  userJoined,
}

class Activity {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? missionId;
  final String? missionTitle;
  final String? teamId;
  final String? teamName;
  final int? points;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.missionId,
    this.missionTitle,
    this.teamId,
    this.teamName,
    this.points,
    required this.createdAt,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.userJoined,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      missionId: data['missionId'],
      missionTitle: data['missionTitle'],
      teamId: data['teamId'],
      teamName: data['teamName'],
      points: data['points'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'missionId': missionId,
      'missionTitle': missionTitle,
      'teamId': teamId,
      'teamName': teamName,
      'points': points,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String getDescription() {
    switch (type) {
      case ActivityType.missionCreated:
        return 'posted a new mission';
      case ActivityType.missionAccepted:
        return 'accepted a mission';
      case ActivityType.missionCompleted:
        return 'completed a mission';
      case ActivityType.teamCreated:
        return 'created a team';
      case ActivityType.userJoined:
        return 'joined Mission Board';
    }
  }

  String? getSubtitle() {
    switch (type) {
      case ActivityType.missionCreated:
      case ActivityType.missionAccepted:
        return missionTitle;
      case ActivityType.missionCompleted:
        return points != null ? '+$points pts' : missionTitle;
      case ActivityType.teamCreated:
        return teamName;
      default:
        return null;
    }
  }
}
