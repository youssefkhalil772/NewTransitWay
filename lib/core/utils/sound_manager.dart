import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static Future<void> playNotification() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/ticket_notify.wav'));
      await HapticFeedback.mediumImpact();
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint('🔈 Sound Error (notification): $e');
    }
  }

  static Future<void> playSuccess() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/ticket_success.wav'));
      await HapticFeedback.heavyImpact();
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint('🔈 Sound Error (success): $e');
    }
  }

  static Future<void> dispose() async {
    // No longer needed for global player
  }
}

