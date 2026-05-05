import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

const double _kCrashThreshold = 30.0;

class CrashDetector {
  // ─── Callbacks ────────────────────────────────────────────────────────────
  /// Called when a crash is detected — starts the trigger flow.
  final VoidCallback onCrashDetected;

  CrashDetector({
    required this.onCrashDetected,
  });

  // ─── Private state ────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Start listening for crash events.
  void start() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen(_onAccelEvent);
    debugPrint('💡 CrashDetector: started');
  }

  /// Stop listening — call this in dispose().
  void stop() {
    _accelSub?.cancel();
    debugPrint('💡 CrashDetector: stopped');
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _onAccelEvent(AccelerometerEvent e) {
    // Calculate total magnitude across all axes in m/s².
    final double magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

    if (magnitude >= _kCrashThreshold) {
      debugPrint('🚨 CrashDetector: impact detected — ${magnitude.toStringAsFixed(2)} m/s²');
      
      onCrashDetected();
      _vibrate();
    }
  }

  Future<void> _vibrate() async {
    try {
      // 1) Long continuous vibration via Vibration package (works on Android)
      final bool hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(duration: 6000, amplitude: 255);
      }

      // 2) Simultaneously fire Flutter's native HapticFeedback in rapid bursts.
      //    heavyImpact uses the phone's haptic engine directly — strongest possible.
      for (int i = 0; i < 12; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } catch (_) {}
  }
}
