import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a lobby room - a live community space
class Lobby {
  final String id;
  final String name;
  final String topic;
  final String description;
  final String? iconEmoji;
  final int onlineCount;
  final int totalMembers;
  final String? pinnedMessage;
  final String? pinnedBy;
  final DateTime? pinnedAt;
  final DateTime createdAt;
  final bool isActive;
  final String type; // 'global', 'topic', 'proximity', 'voice-stage'
  final Map<String, dynamic>? settings; // rate limit, permissions, etc.

  Lobby({
    required this.id,
    required this.name,
    required this.topic,
    required this.description,
    this.iconEmoji,
    this.onlineCount = 0,
    this.totalMembers = 0,
    this.pinnedMessage,
    this.pinnedBy,
    this.pinnedAt,
    required this.createdAt,
    this.isActive = true,
    this.type = 'global',
    this.settings,
  });

  factory Lobby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime createdAt;
    try {
      final timestamp = data['createdAt'];
      if (timestamp is Timestamp) {
        createdAt = timestamp.toDate();
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime? pinnedAt;
    try {
      final timestamp = data['pinnedAt'];
      if (timestamp is Timestamp) {
        pinnedAt = timestamp.toDate();
      }
    } catch (e) {
      pinnedAt = null;
    }

    return Lobby(
      id: doc.id,
      name: data['name'] ?? 'Lobby',
      topic: data['topic'] ?? 'General',
      description: data['description'] ?? '',
      iconEmoji: data['iconEmoji'],
      onlineCount: data['onlineCount'] ?? 0,
      totalMembers: data['totalMembers'] ?? 0,
      pinnedMessage: data['pinnedMessage'],
      pinnedBy: data['pinnedBy'],
      pinnedAt: pinnedAt,
      createdAt: createdAt,
      isActive: data['isActive'] ?? true,
      type: data['type'] ?? 'global',
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'topic': topic,
      'description': description,
      'iconEmoji': iconEmoji,
      'onlineCount': onlineCount,
      'totalMembers': totalMembers,
      'pinnedMessage': pinnedMessage,
      'pinnedBy': pinnedBy,
      'pinnedAt': pinnedAt != null ? Timestamp.fromDate(pinnedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'type': type,
      'settings': settings,
    };
  }

  Lobby copyWith({
    String? name,
    String? topic,
    String? description,
    String? iconEmoji,
    int? onlineCount,
    int? totalMembers,
    String? pinnedMessage,
    String? pinnedBy,
    DateTime? pinnedAt,
    bool? isActive,
    String? type,
    Map<String, dynamic>? settings,
  }) {
    return Lobby(
      id: id,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      onlineCount: onlineCount ?? this.onlineCount,
      totalMembers: totalMembers ?? this.totalMembers,
      pinnedMessage: pinnedMessage ?? this.pinnedMessage,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      settings: settings ?? this.settings,
    );
  }
}

/// User rank/status in lobby
enum LobbyRank {
  guest,    // First time visitor
  member,   // Regular member
  og,       // Original member (early joiner)
  mod,      // Moderator
  admin;    // Admin

  String get displayName {
    switch (this) {
      case LobbyRank.guest:
        return 'Guest';
      case LobbyRank.member:
        return 'Member';
      case LobbyRank.og:
        return 'OG';
      case LobbyRank.mod:
        return 'Mod';
      case LobbyRank.admin:
        return 'Admin';
    }
  }

  String get emoji {
    switch (this) {
      case LobbyRank.guest:
        return '👋';
      case LobbyRank.member:
        return '✅';
      case LobbyRank.og:
        return '⭐';
      case LobbyRank.mod:
        return '🛡️';
      case LobbyRank.admin:
        return '👑';
    }
  }
}

/// User presence in lobby
class LobbyUser {
  final String uid;
  final String displayName;
  final String? photoURL;
  final LobbyRank rank;
  final DateTime joinedAt;
  final DateTime lastSeen;
  final bool isTyping;

  LobbyUser({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.rank,
    required this.joinedAt,
    required this.lastSeen,
    this.isTyping = false,
  });

  factory LobbyUser.fromMap(Map<String, dynamic> data) {
    DateTime joinedAt;
    try {
      final timestamp = data['joinedAt'];
      if (timestamp is Timestamp) {
        joinedAt = timestamp.toDate();
      } else {
        joinedAt = DateTime.now();
      }
    } catch (e) {
      joinedAt = DateTime.now();
    }

    DateTime lastSeen;
    try {
      final timestamp = data['lastSeen'];
      if (timestamp is Timestamp) {
        lastSeen = timestamp.toDate();
      } else {
        lastSeen = DateTime.now();
      }
    } catch (e) {
      lastSeen = DateTime.now();
    }

    return LobbyUser(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? 'Unknown',
      photoURL: data['photoURL'],
      rank: LobbyRank.values.firstWhere(
        (r) => r.name == data['rank'],
        orElse: () => LobbyRank.member,
      ),
      joinedAt: joinedAt,
      lastSeen: lastSeen,
      isTyping: data['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoURL': photoURL,
      'rank': rank.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isTyping': isTyping,
    };
  }

  bool get isOnline {
    final diff = DateTime.now().difference(lastSeen);
    return diff.inMinutes < 5;
  }
}
