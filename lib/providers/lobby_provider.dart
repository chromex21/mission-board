import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lobby_message_model.dart';

class LobbyProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<LobbyMessage> _messages = [];
  bool isLoading = false;
  String? errorMessage;

  List<LobbyMessage> get messages => _messages;

  // Stream lobby messages
  Stream<List<LobbyMessage>> streamLobbyMessages() {
    return _db
        .collection('lobby')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          _messages = snapshot.docs
              .map((doc) => LobbyMessage.fromFirestore(doc))
              .toList();
          return _messages;
        });
  }

  // Send message to lobby
  Future<LobbyMessage?> sendMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    String? missionId,
    String? missionTitle,
  }) async {
    try {
      final mentions = LobbyMessage.extractMentions(content);

      final message = LobbyMessage(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        mentions: mentions,
        missionId: missionId,
        missionTitle: missionTitle,
        createdAt: DateTime.now(),
      );

      final docRef = await _db.collection('lobby').add(message.toMap());
      return LobbyMessage(
        id: docRef.id,
        userId: message.userId,
        userName: message.userName,
        userPhotoUrl: message.userPhotoUrl,
        content: message.content,
        mentions: message.mentions,
        missionId: message.missionId,
        missionTitle: message.missionTitle,
        createdAt: message.createdAt,
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Delete message (only own messages)
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final doc = await _db.collection('lobby').doc(messageId).get();
      if (doc.exists && doc.data()?['userId'] == userId) {
        await doc.reference.delete();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
