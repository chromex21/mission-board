import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyMessage {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final List<String> mentions;
  final String? missionId;
  final String? missionTitle;
  final DateTime createdAt;

  LobbyMessage({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    this.mentions = const [],
    this.missionId,
    this.missionTitle,
    required this.createdAt,
  });

  factory LobbyMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LobbyMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      mentions: List<String>.from(data['mentions'] ?? []),
      missionId: data['missionId'],
      missionTitle: data['missionTitle'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'mentions': mentions,
      'missionId': missionId,
      'missionTitle': missionTitle,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Extract @mentions from content
  static List<String> extractMentions(String content) {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(content).map((match) => match.group(1)!).toList();
  }
}
