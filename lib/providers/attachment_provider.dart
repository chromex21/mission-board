import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attachment_model.dart';

class AttachmentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, List<Attachment>> _attachmentsByMission =
      <String, List<Attachment>>{};
  bool isLoading = false;
  String? errorMessage;

  List<Attachment> getAttachmentsForMission(String missionId) {
    return _attachmentsByMission[missionId] ?? [];
  }

  Stream<List<Attachment>> streamAttachmentsForMission(String missionId) {
    return _db
        .collection('attachments')
        .where('missionId', isEqualTo: missionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final attachments = snapshot.docs
              .map((doc) => Attachment.fromFirestore(doc))
              .toList();

          _attachmentsByMission[missionId] = attachments;
          return attachments;
        });
  }

  Future<Attachment?> addAttachment({
    required String missionId,
    String? commentId,
    required String userId,
    required String url,
    String? fileName,
    String? description,
  }) async {
    try {
      final attachmentData = Attachment(
        id: '',
        missionId: missionId,
        commentId: commentId,
        userId: userId,
        url: url,
        fileName: fileName,
        description: description,
      );

      final docRef = await _db
          .collection('attachments')
          .add(attachmentData.toMap());
      final doc = await docRef.get();

      final newAttachment = Attachment.fromFirestore(doc);

      // Update local cache
      if (_attachmentsByMission.containsKey(missionId)) {
        _attachmentsByMission[missionId]!.add(newAttachment);
        notifyListeners();
      }

      return newAttachment;
    } catch (e) {
      errorMessage = 'Failed to add attachment';
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteAttachment(String attachmentId, String missionId) async {
    try {
      await _db.collection('attachments').doc(attachmentId).delete();

      // Update local cache
      if (_attachmentsByMission.containsKey(missionId)) {
        _attachmentsByMission[missionId]!.removeWhere(
          (a) => a.id == attachmentId,
        );
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to delete attachment';
      notifyListeners();
    }
  }

  int getAttachmentCount(String missionId) {
    return _attachmentsByMission[missionId]?.length ?? 0;
  }

  void clearCache() {
    _attachmentsByMission.clear();
    notifyListeners();
  }
}
