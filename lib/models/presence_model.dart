import 'package:cloud_firestore/cloud_firestore.dart';

/// User presence status
enum PresenceStatus { online, away, offline }

/// Typing status
class TypingStatus {
  final String userId;
  final String conversationId;
  final DateTime timestamp;

  TypingStatus({
    required this.userId,
    required this.conversationId,
    required this.timestamp,
  });

  factory TypingStatus.fromMap(Map<String, dynamic> map) {
    return TypingStatus(
      userId: map['userId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'conversationId': conversationId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// User presence information
class UserPresence {
  final String userId;
  final PresenceStatus status;
  final DateTime lastSeen;
  final String? currentActivity; // e.g., "Completing Mission: XYZ"

  UserPresence({
    required this.userId,
    required this.status,
    required this.lastSeen,
    this.currentActivity,
  });

  factory UserPresence.fromMap(Map<String, dynamic> map, String userId) {
    return UserPresence(
      userId: userId,
      status: PresenceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PresenceStatus.offline,
      ),
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      currentActivity: map['currentActivity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'lastSeen': Timestamp.fromDate(lastSeen),
      if (currentActivity != null) 'currentActivity': currentActivity,
    };
  }

  /// Get user-friendly status text
  String getStatusText() {
    if (status == PresenceStatus.online) {
      return currentActivity ?? 'Online';
    } else if (status == PresenceStatus.away) {
      return 'Away';
    } else {
      return _getLastSeenText();
    }
  }

  String _getLastSeenText() {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return 'Last seen ${diff.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
