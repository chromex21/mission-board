import 'package:cloud_firestore/cloud_firestore.dart';

enum CommentType { text, system }

class Comment {
  final String id;
  final String missionId;
  final String userId;
  final String content;
  final CommentType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final List<String> mentions; // User IDs mentioned with @
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;

  Comment({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.content,
    this.type = CommentType.text,
    DateTime? createdAt,
    this.updatedAt,
    this.isEdited = false,
    List<String>? mentions,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
  }) : mentions = mentions ?? [],
       createdAt = createdAt ?? DateTime.now();

  // System comment factory
  factory Comment.system({required String missionId, required String content}) {
    return Comment(
      id: '',
      missionId: missionId,
      userId: 'system',
      content: content,
      type: CommentType.system,
    );
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      missionId: data['missionId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      type: CommentType.values.firstWhere(
        (e) => e.toString() == 'CommentType.${data['type'] ?? 'text'}',
        orElse: () => CommentType.text,
      ),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : null,
      isEdited: data['isEdited'] ?? false,
      mentions: List<String>.from(data['mentions'] ?? []),
      linkPreviewUrl: data['linkPreviewUrl'],
      linkPreviewTitle: data['linkPreviewTitle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'userId': userId,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isEdited': isEdited,
      'mentions': mentions,
      'linkPreviewUrl': linkPreviewUrl,
      'linkPreviewTitle': linkPreviewTitle,
    };
  }

  Comment copyWith({
    String? id,
    String? missionId,
    String? userId,
    String? content,
    CommentType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    List<String>? mentions,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
  }) {
    return Comment(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      mentions: mentions ?? this.mentions,
      linkPreviewUrl: linkPreviewUrl ?? this.linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
    );
  }

  // Extract mentions from content (@username)
  static List<String> extractMentions(String content, List<String> userIds) {
    final mentioned = <String>[];
    final words = content.split(' ');

    for (final word in words) {
      if (word.startsWith('@')) {
        // In production, you'd match against actual usernames
        // For now, we'll just store the mention text
      }
    }

    return mentioned;
  }

  // Detect URLs for link preview
  static String? extractUrl(String content) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );
    final match = urlPattern.firstMatch(content);
    return match?.group(0);
  }
}
