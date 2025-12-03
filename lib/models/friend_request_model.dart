import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map, String id) {
    return FriendRequest(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }
}

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  newMessage,
  missionCompleted,
  missionAssigned,
  missionApproved,
  achievementUnlocked,
  levelUp,
}

class AppNotification {
  final String id;
  final String userId; // Who receives this notification
  final NotificationType type;
  final String title;
  final String message;
  final String? actorId; // Who triggered this notification
  final String? actorName;
  final String? actionId; // Related mission/conversation/etc ID
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.actorId,
    this.actorName,
    this.actionId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.newMessage,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      actorId: map['actorId'],
      actorName: map['actorName'],
      actionId: map['actionId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'actorId': actorId,
      'actorName': actorName,
      'actionId': actionId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
