import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

class TeamProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Team> teams = [];
  bool isLoading = true;
  String? errorMessage;

  TeamProvider() {
    _listenToTeams();
  }

  void _listenToTeams() {
    _db
        .collection('teams')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            teams = snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            errorMessage = 'Failed to load teams';
            isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<Team?> createTeam({
    required String name,
    required String ownerId,
    String? description,
  }) async {
    try {
      final teamData = Team(
        id: '',
        name: name,
        description: description,
        ownerId: ownerId,
      );

      final docRef = await _db.collection('teams').add(teamData.toMap());
      final doc = await docRef.get();
      return Team.fromFirestore(doc);
    } catch (e) {
      errorMessage = 'Failed to create team';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateTeam(
    String teamId, {
    String? name,
    String? description,
  }) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      errorMessage = 'Failed to update team';
      notifyListeners();
    }
  }

  Future<void> addMember(
    String teamId,
    String userId, {
    bool asAdmin = false,
  }) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        if (asAdmin)
          'adminIds': FieldValue.arrayUnion([userId])
        else
          'memberIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      errorMessage = 'Failed to add member';
      notifyListeners();
    }
  }

  Future<void> removeMember(String teamId, String userId) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        'adminIds': FieldValue.arrayRemove([userId]),
        'memberIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      errorMessage = 'Failed to remove member';
      notifyListeners();
    }
  }

  Future<void> promoteToAdmin(String teamId, String userId) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      errorMessage = 'Failed to promote member';
      notifyListeners();
    }
  }

  Future<void> demoteToMember(String teamId, String userId) async {
    try {
      await _db.collection('teams').doc(teamId).update({
        'adminIds': FieldValue.arrayRemove([userId]),
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      errorMessage = 'Failed to demote member';
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      // Soft delete - set isActive to false to hide from queries
      await _db.collection('teams').doc(teamId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Note: This archives the team. To permanently delete, use:
      // await _db.collection('teams').doc(teamId).delete();
    } catch (e) {
      errorMessage = 'Failed to archive team';
      notifyListeners();
      throw Exception('Failed to archive team: ${e.toString()}');
    }
  }

  List<Team> getUserTeams(String userId) {
    return teams.where((team) => team.isMember(userId)).toList();
  }

  Team? getTeamById(String teamId) {
    try {
      return teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }
}
