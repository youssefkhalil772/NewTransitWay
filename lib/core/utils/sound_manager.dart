import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playNotification() async {
    try {
      await _player.play(AssetSource('sounds/ticket_notify.wav'));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('🔈 Sound Error (notification): $e');
    }
  }

  static Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource('sounds/ticket_success.wav'));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('🔈 Sound Error (success): $e');
    }
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}
