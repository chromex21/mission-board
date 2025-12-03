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
  final String messageType; // 'text', 'image', 'gif', 'sticker'
  final String? mediaUrl;

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
    this.messageType = 'text',
    this.mediaUrl,
  });

  factory LobbyMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle timestamp - could be Timestamp or null
    DateTime createdAt;
    try {
      final timestamp = data['createdAt'];
      if (timestamp == null) {
        createdAt = DateTime.now();
      } else if (timestamp is Timestamp) {
        createdAt = timestamp.toDate();
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    return LobbyMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      mentions: List<String>.from(data['mentions'] ?? []),
      missionId: data['missionId'],
      missionTitle: data['missionTitle'],
      createdAt: createdAt,
      messageType: data['messageType'] ?? 'text',
      mediaUrl: data['mediaUrl'],
    );
  }

  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'mentions': mentions,
      'missionId': missionId,
      'missionTitle': missionTitle,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  // Extract @mentions from content
  static List<String> extractMentions(String content) {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(content).map((match) => match.group(1)!).toList();
  }
}
