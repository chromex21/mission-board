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
  final String?
  deepLinkRoute; // Route to navigate when tapped (e.g., '/missions/123')
  final Map<String, dynamic>?
  actionData; // Extra data for actions (button labels, callbacks)

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
    this.deepLinkRoute,
    this.actionData,
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
      deepLinkRoute: map['deepLinkRoute'],
      actionData: map['actionData'] != null
          ? Map<String, dynamic>.from(map['actionData'])
          : null,
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
      if (deepLinkRoute != null) 'deepLinkRoute': deepLinkRoute,
      if (actionData != null) 'actionData': actionData,
    };
  }

  /// Generate deep link based on notification type
  String getDefaultRoute() {
    if (deepLinkRoute != null) return deepLinkRoute!;

    switch (type) {
      case NotificationType.friendRequest:
        return actorId != null ? '/profile/$actorId' : '/friends';
      case NotificationType.friendRequestAccepted:
        return actorId != null ? '/messages/$actorId' : '/messages';
      case NotificationType.newMessage:
        return actionId != null ? '/messages/$actionId' : '/messages';
      case NotificationType.missionAssigned:
      case NotificationType.missionCompleted:
      case NotificationType.missionApproved:
        return actionId != null ? '/missions/$actionId/detail' : '/missions';
      case NotificationType.levelUp:
      case NotificationType.achievementUnlocked:
        return '/profile';
    }
  }
}
