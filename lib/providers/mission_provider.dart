import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mission_model.dart';
import '../models/activity_model.dart';
import 'activity_provider.dart';

class MissionProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityProvider? activityProvider;
  List<Mission> missions = [];
  bool isLoading = true;
  String? errorMessage;

  MissionProvider({this.activityProvider}) {
    _listenToMissions();
  }

  void _listenToMissions() {
    _db
        .collection('missions')
        .where(
          'status',
          whereIn: ['open', 'assigned', 'pending_review', 'completed'],
        )
        .snapshots()
        .listen(
          (snapshot) {
            missions =
                snapshot.docs.map((doc) => Mission.fromFirestore(doc)).toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                      a.createdAt ?? DateTime.now(),
                    ),
                  );
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            errorMessage = 'Failed to load missions. Please try again.';
            isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> fetchOpenMissions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final query = await _db
          .collection('missions')
          .where(
            'status',
            whereIn: ['open', 'assigned', 'pending_review', 'completed'],
          )
          .get();
      missions = query.docs.map((doc) => Mission.fromFirestore(doc)).toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load missions. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMission(
    Mission mission, {
    String? userName,
    String? userPhotoUrl,
  }) async {
    await _db.collection('missions').add(mission.toMap());

    // Log activity
    if (activityProvider != null && userName != null) {
      await activityProvider!.logActivity(
        type: ActivityType.missionCreated,
        userId: mission.createdBy,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        missionId: mission.id,
        missionTitle: mission.title,
      );
    }
  }

  Future<void> assignMission(
    String missionId,
    String userId, {
    String? userName,
    String? userPhotoUrl,
  }) async {
    try {
      // Use transaction to prevent race condition
      await _db.runTransaction((transaction) async {
        final doc = await transaction.get(
          _db.collection('missions').doc(missionId),
        );

        if (!doc.exists) {
          throw Exception('Mission not found');
        }

        final data = doc.data()!;

        if (data['status'] != 'open') {
          throw Exception('Mission is no longer available');
        }

        // Update mission atomically
        transaction.update(doc.reference, {
          'assignedTo': userId,
          'status': 'assigned',
          'assignedAt': DateTime.now().millisecondsSinceEpoch,
        });
      });

      // Log activity after successful assignment
      if (activityProvider != null && userName != null) {
        final doc = await _db.collection('missions').doc(missionId).get();
        await activityProvider!.logActivity(
          type: ActivityType.missionAccepted,
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          missionId: missionId,
          missionTitle: doc.data()?['title'] ?? 'Unknown',
        );
      }
    } catch (e) {
      throw Exception('Failed to accept mission: ${e.toString()}');
    }
  }

  Future<void> completeMission(
    String missionId,
    String userId, {
    String? proofNote,
  }) async {
    final doc = await _db.collection('missions').doc(missionId).get();
    final data = doc.data();
    if (data != null &&
        data['assignedTo'] == userId &&
        data['status'] == 'assigned') {
      await _db.collection('missions').doc(missionId).update({
        'status': 'pending_review',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        if (proofNote != null) 'proofNote': proofNote,
      });
    } else {
      throw Exception('Cannot complete this mission');
    }
  }

  Future<void> approveMission(
    String missionId,
    String userId,
    int rewardPoints,
    int difficulty, {
    String? userName,
    String? userPhotoUrl,
  }) async {
    final doc = await _db.collection('missions').doc(missionId).get();
    final data = doc.data();
    if (data != null && data['status'] == 'pending_review') {
      // Update mission to completed
      await _db.collection('missions').doc(missionId).update({
        'status': 'completed',
      });

      // Log activity
      if (activityProvider != null && userName != null) {
        await activityProvider!.logActivity(
          type: ActivityType.missionCompleted,
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          missionId: missionId,
          missionTitle: data['title'],
          points: rewardPoints,
        );
      }

      // Award points, update level, streak, and achievements
      final userRef = _db.collection('users').doc(userId);
      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final currentPoints = userData['totalPoints'] ?? 0;
          final currentCompleted = userData['completedMissions'] ?? 0;
          final currentStreak = userData['currentStreak'] ?? 0;
          final bestStreak = userData['bestStreak'] ?? 0;
          final lastCompletion = userData['lastCompletionDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  userData['lastCompletionDate'],
                )
              : null;

          // Calculate new points and level
          final newPoints = currentPoints + rewardPoints;
          final newLevel = (newPoints / 100).floor() + 1;

          // Calculate streak
          int newStreak = currentStreak;
          final now = DateTime.now();
          if (lastCompletion != null) {
            final daysSinceLastCompletion = now
                .difference(lastCompletion)
                .inDays;
            if (daysSinceLastCompletion == 1) {
              // Consecutive day
              newStreak = currentStreak + 1;
            } else if (daysSinceLastCompletion > 1) {
              // Streak broken
              newStreak = 1;
            }
            // Same day doesn't change streak
          } else {
            newStreak = 1;
          }

          final newBestStreak = newStreak > bestStreak ? newStreak : bestStreak;

          // Check for new achievements (import needed at top of file)
          // We'll calculate this in UI for now to avoid circular dependency

          transaction.update(userRef, {
            'totalPoints': newPoints,
            'completedMissions': currentCompleted + 1,
            'level': newLevel,
            'currentStreak': newStreak,
            'bestStreak': newBestStreak,
            'lastCompletionDate': now.millisecondsSinceEpoch,
          });
        }
      });
    } else {
      throw Exception('Mission cannot be approved');
    }
  }

  Future<void> rejectMission(String missionId) async {
    final doc = await _db.collection('missions').doc(missionId).get();
    final data = doc.data();
    if (data != null && data['status'] == 'pending_review') {
      await _db.collection('missions').doc(missionId).update({
        'status': 'assigned',
        'completedAt': null,
        'proofNote': null,
      });
    } else {
      throw Exception('Mission cannot be rejected');
    }
  }

  // Alias for assignMission to match marketplace UI
  Future<void> acceptMission(
    String missionId,
    String userId, {
    String? userName,
    String? userPhotoUrl,
  }) async {
    return assignMission(
      missionId,
      userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
    );
  }

  // Fetch missions (refresh)
  Future<void> fetchMissions() async {
    return fetchOpenMissions();
  }
}
