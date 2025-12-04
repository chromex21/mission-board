import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants; // User IDs
  final Map<String, dynamic> participantDetails; // {uid: {name, avatar}}
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // {uid: count}
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String id) {
    final now = DateTime.now();
    return Conversation(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantDetails: Map<String, dynamic>.from(
        map['participantDetails'] ?? {},
      ),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy; // User IDs who read this message
  final MessageStatus status; // Delivery status
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<MessageReaction> reactions; // Emoji reactions
  final MessageReply? replyTo; // Reply reference
  final String? attachmentUrl; // For file/image messages
  final Map<String, dynamic>?
  metadata; // Extra data (file size, dimensions, etc.)
  final bool isEdited; // Whether message was edited
  final DateTime? editedAt; // When message was last edited

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.readAt,
    this.reactions = const [],
    this.replyTo,
    this.attachmentUrl,
    this.metadata,
    this.isEdited = false,
    this.editedAt,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    // Handle timestamp safely
    DateTime timestamp;
    try {
      final ts = map['timestamp'];
      if (ts == null) {
        timestamp = DateTime.now();
      } else if (ts is Timestamp) {
        timestamp = ts.toDate();
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Parse reactions
    List<MessageReaction> reactions = [];
    if (map['reactions'] != null) {
      reactions = (map['reactions'] as List)
          .map((r) => MessageReaction.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    // Parse reply
    MessageReply? replyTo;
    if (map['replyTo'] != null) {
      replyTo = MessageReply.fromMap(map['replyTo'] as Map<String, dynamic>);
    }

    return Message(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: timestamp,
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      readAt: map['readAt'] != null
          ? (map['readAt'] as Timestamp).toDate()
          : null,
      reactions: reactions,
      replyTo: replyTo,
      attachmentUrl: map['attachmentUrl'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'status': status.name,
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
      'reactions': reactions.map((r) => r.toMap()).toList(),
      if (replyTo != null) 'replyTo': replyTo!.toMap(),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (metadata != null) 'metadata': metadata,
      'isEdited': isEdited,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
    };
  }
}

enum MessageType { text, image, gif, file, voice, system }

enum MessageStatus {
  sending, // Local only, not yet sent
  sent, // Delivered to server
  delivered, // Delivered to recipient device
  read, // Read by recipient
  failed, // Failed to send
}

/// Message reaction
class MessageReaction {
  final String emoji;
  final String userId;
  final DateTime timestamp;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      emoji: map['emoji'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emoji': emoji,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Reply reference
class MessageReply {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;

  MessageReply({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
  });

  factory MessageReply.fromMap(Map<String, dynamic> map) {
    return MessageReply(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
    };
  }
}

// For image/gif messages, content will be the URL
// For text with mentions, content includes @username patterns
