import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';

class ActivityProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Activity> _recentActivities = [];
  bool isLoading = false;
  String? errorMessage;

  List<Activity> get recentActivities => _recentActivities;

  // Stream recent activities (last 50)
  Stream<List<Activity>> streamRecentActivities() {
    return _db
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          _recentActivities = snapshot.docs
              .map((doc) => Activity.fromFirestore(doc))
              .toList();
          return _recentActivities;
        });
  }

  // Log activity
  Future<void> logActivity({
    required ActivityType type,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? missionId,
    String? missionTitle,
    String? teamId,
    String? teamName,
    int? points,
  }) async {
    try {
      final activity = Activity(
        id: '',
        type: type,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        missionId: missionId,
        missionTitle: missionTitle,
        teamId: teamId,
        teamName: teamName,
        points: points,
        createdAt: DateTime.now(),
      );

      await _db.collection('activities').add(activity.toMap());
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear old activities (optional - to keep database clean)
  Future<void> clearOldActivities({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final oldActivities = await _db
          .collection('activities')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (var doc in oldActivities.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
