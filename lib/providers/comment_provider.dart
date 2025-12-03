import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, List<Comment>> _commentsByMission =
      <String, List<Comment>>{};
  bool isLoading = false;
  String? errorMessage;

  List<Comment> getCommentsForMission(String missionId) {
    return _commentsByMission[missionId] ?? [];
  }

  Stream<List<Comment>> streamCommentsForMission(String missionId) {
    return _db
        .collection('comments')
        .where('missionId', isEqualTo: missionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .toList();

          _commentsByMission[missionId] = comments;
          return comments;
        });
  }

  Future<Comment?> addComment({
    required String missionId,
    required String userId,
    required String content,
    List<String>? mentions,
  }) async {
    try {
      // Extract URL for link preview
      final url = Comment.extractUrl(content);

      final commentData = Comment(
        id: '',
        missionId: missionId,
        userId: userId,
        content: content,
        mentions: mentions ?? [],
        linkPreviewUrl: url,
      );

      final docRef = await _db.collection('comments').add(commentData.toMap());
      final doc = await docRef.get();

      final newComment = Comment.fromFirestore(doc);

      // Update local cache
      if (_commentsByMission.containsKey(missionId)) {
        _commentsByMission[missionId]!.add(newComment);
        notifyListeners();
      }

      return newComment;
    } catch (e) {
      errorMessage = 'Failed to add comment';
      notifyListeners();
      return null;
    }
  }

  Future<void> addSystemComment({
    required String missionId,
    required String content,
  }) async {
    try {
      final commentData = Comment.system(
        missionId: missionId,
        content: content,
      );

      await _db.collection('comments').add(commentData.toMap());
    } catch (e) {
      errorMessage = 'Failed to add system comment';
      notifyListeners();
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _db.collection('comments').doc(commentId).update({
        'content': content,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'isEdited': true,
        'linkPreviewUrl': Comment.extractUrl(content),
      });
    } catch (e) {
      errorMessage = 'Failed to update comment';
      notifyListeners();
    }
  }

  Future<void> deleteComment(String commentId, String missionId) async {
    try {
      await _db.collection('comments').doc(commentId).delete();

      // Update local cache
      if (_commentsByMission.containsKey(missionId)) {
        _commentsByMission[missionId]!.removeWhere((c) => c.id == commentId);
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to delete comment';
      notifyListeners();
    }
  }

  int getCommentCount(String missionId) {
    return _commentsByMission[missionId]?.length ?? 0;
  }

  void clearCache() {
    _commentsByMission.clear();
    notifyListeners();
  }
}
