import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  double _volume = 0.7;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  SoundService() {
    _player.setVolume(_volume);
  }

  /// Toggle sound on/off
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    notifyListeners();
  }

  /// Play sound effect
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled) return;

    try {
      await _player.play(AssetSource(_getSoundPath(effect)));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }

  String _getSoundPath(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.missionAccepted:
        return 'sounds/mission_accepted.mp3';
      case SoundEffect.missionCompleted:
        return 'sounds/mission_completed.mp3';
      case SoundEffect.levelUp:
        return 'sounds/level_up.mp3';
      case SoundEffect.newMessage:
        return 'sounds/new_message.mp3';
      case SoundEffect.notification:
        return 'sounds/notification.mp3';
      case SoundEffect.achievement:
        return 'sounds/achievement.mp3';
      case SoundEffect.error:
        return 'sounds/error.mp3';
      case SoundEffect.success:
        return 'sounds/success.mp3';
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

enum SoundEffect {
  missionAccepted,
  missionCompleted,
  levelUp,
  newMessage,
  notification,
  achievement,
  error,
  success,
}
