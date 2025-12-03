enum UserRole { admin, worker }

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final int totalPoints;
  final int completedMissions;
  final DateTime? createdAt;
  final int level;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastCompletionDate;
  final List<String> achievements;

  // Mission ID Card fields
  final String? displayName;
  final String? username;
  final String? photoURL;
  final String? country;
  final String? countryCode; // ISO 3166-1 alpha-2 (e.g., 'US', 'GB')
  final String? phoneNumber;
  final String? bio;
  final double successRate; // Percentage of missions completed successfully
  final String missionId; // Unique 8-character ID (e.g., 'MX-A47B9C')

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.totalPoints = 0,
    this.completedMissions = 0,
    this.createdAt,
    this.level = 1,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletionDate,
    this.achievements = const [],
    this.displayName,
    this.username,
    this.photoURL,
    this.country,
    this.countryCode,
    this.phoneNumber,
    this.bio,
    this.successRate = 100.0,
    String? missionId,
  }) : missionId = missionId ?? _generateMissionId(uid);

  static String _generateMissionId(String uid) {
    // Generate format: MX-A47B9C (MX = Mission X, followed by 6 alphanumeric chars)
    final hash = uid.hashCode.abs().toRadixString(36).toUpperCase();
    final suffix = hash.length >= 6
        ? hash.substring(0, 6)
        : hash.padRight(6, '0');
    return 'MX-$suffix';
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role'] ?? 'worker'}',
        orElse: () => UserRole.worker,
      ),
      totalPoints: data['totalPoints'] ?? 0,
      completedMissions: data['completedMissions'] ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null,
      level: data['level'] ?? 1,
      currentStreak: data['currentStreak'] ?? 0,
      bestStreak: data['bestStreak'] ?? 0,
      lastCompletionDate: data['lastCompletionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastCompletionDate'])
          : null,
      achievements: data['achievements'] != null
          ? List<String>.from(data['achievements'])
          : [],
      displayName: data['displayName'],
      username: data['username'],
      photoURL: data['photoURL'],
      country: data['country'],
      countryCode: data['countryCode'],
      phoneNumber: data['phoneNumber'],
      bio: data['bio'],
      successRate: data['successRate']?.toDouble() ?? 100.0,
      missionId: data['missionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.name,
      'totalPoints': totalPoints,
      'completedMissions': completedMissions,
      'createdAt':
          createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'level': level,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletionDate': lastCompletionDate?.millisecondsSinceEpoch,
      'achievements': achievements,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'country': country,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'successRate': successRate,
      'missionId': missionId,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? username,
    String? photoURL,
    String? country,
    String? countryCode,
    String? phoneNumber,
    String? bio,
    int? totalPoints,
    int? completedMissions,
    int? level,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompletionDate,
    List<String>? achievements,
    double? successRate,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      completedMissions: completedMissions ?? this.completedMissions,
      createdAt: createdAt,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      achievements: achievements ?? this.achievements,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      successRate: successRate ?? this.successRate,
      missionId: missionId,
    );
  }

  // Calculate level from total points (100 points per level)
  static int calculateLevel(int points) {
    return (points / 100).floor() + 1;
  }

  // Calculate XP progress to next level
  static int getXPForCurrentLevel(int points) {
    return points % 100;
  }

  // Calculate total XP needed for next level
  static int getXPForNextLevel() {
    return 100;
  }

  // Get rank title based on level
  static String getRankTitle(int level) {
    if (level >= 50) return 'Legendary';
    if (level >= 40) return 'Master';
    if (level >= 30) return 'Expert';
    if (level >= 20) return 'Veteran';
    if (level >= 10) return 'Skilled';
    if (level >= 5) return 'Apprentice';
    return 'Novice';
  }
}
