import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundManager {
  static AudioPlayer? _player;

  static AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  static Future<void> playNotification() async {
    try {
      // Play from local asset (faster & works offline)
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/ticket_notify.wav'));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('🔈 Sound Error (notification): $e');
      // Fallback to system sound + haptic only
      try {
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  static Future<void> playSuccess() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/ticket_success.wav'));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('🔈 Sound Error (success): $e');
      try {
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  static Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
