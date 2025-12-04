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
  final String
  messageType; // 'text', 'image', 'gif', 'sticker', 'voice', 'system'
  final String? mediaUrl;

  // Voice note fields
  final int? voiceDuration; // in seconds

  // Reactions field
  final Map<String, List<String>>? reactions; // emoji -> [userId1, userId2...]

  // Reply-to field
  final String? replyToId; // ID of message being replied to
  final String? replyToContent; // Preview of original message
  final String? replyToUserName; // Name of original message author

  // System message metadata
  final String? systemType; // 'join', 'leave', 'welcome', 'pin', 'rank_change'
  final Map<String, dynamic>? systemData; // Additional system message data

  // User rank (for display)
  final String? userRank; // 'guest', 'member', 'og', 'mod', 'admin'

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
    this.voiceDuration,
    this.reactions,
    this.replyToId,
    this.replyToContent,
    this.replyToUserName,
    this.systemType,
    this.systemData,
    this.userRank,
  });

  bool get isSystemMessage => messageType == 'system';

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

    // Parse reactions
    Map<String, List<String>>? reactions;
    if (data['reactions'] != null) {
      reactions = (data['reactions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      );
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
      voiceDuration: data['voiceDuration'],
      reactions: reactions,
      replyToId: data['replyToId'],
      replyToContent: data['replyToContent'],
      replyToUserName: data['replyToUserName'],
      systemType: data['systemType'],
      systemData: data['systemData'],
      userRank: data['userRank'],
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
      'systemType': systemType,
      'systemData': systemData,
      'userRank': userRank,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'voiceDuration': voiceDuration,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToUserName': replyToUserName,
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
