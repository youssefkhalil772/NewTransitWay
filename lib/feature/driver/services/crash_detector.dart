import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

// Impact threshold using linear acceleration (m/s²). 
// 20 = strong shake, 30 = actual crash.
const double _kCrashThreshold = 22.0;

// Minimum time between triggers to prevent spam.
const Duration _kCooldown = Duration(seconds: 30);

class CrashDetector {
  final VoidCallback onCrashDetected;

  CrashDetector({required this.onCrashDetected});

  // ─── Private state ────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  bool _isInCooldown = false;

  // Low-pass filter: gravity vector estimate
  double _gx = 0, _gy = 0, _gz = 9.8;

  // Gyroscope: rotational speed (rad/s)
  double _gyroMagnitude = 0;

  // ─── Public API ───────────────────────────────────────────────────────────
  void start() {
    _accelSub?.cancel();
    _gyroSub?.cancel();

    // Track rotation speed via gyroscope (helps distinguish crash vs. pocket shake)
    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen((e) {
        _gyroMagnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      });
    } catch (e) {
      debugPrint('⚠️ CrashDetector: Gyroscope not available: $e');
    }

    // Listen for accelerometer events
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(_onAccelEvent);

    debugPrint('💡 CrashDetector: started (threshold=${_kCrashThreshold}m/s²)');
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    debugPrint('💡 CrashDetector: stopped');
  }

  // ─── Private helpers ──────────────────────────────────────────────────────
  void _onAccelEvent(AccelerometerEvent e) {
    // --- Step 1: Low-pass filter to isolate gravity ---
    const double alpha = 0.8;
    _gx = alpha * _gx + (1 - alpha) * e.x;
    _gy = alpha * _gy + (1 - alpha) * e.y;
    _gz = alpha * _gz + (1 - alpha) * e.z;

    // --- Step 2: Subtract gravity = linear acceleration only ---
    final double lx = e.x - _gx;
    final double ly = e.y - _gy;
    final double lz = e.z - _gz;
    final double linearMag = sqrt(lx * lx + ly * ly + lz * lz);

    if (linearMag >= _kCrashThreshold) {
      debugPrint(
        '🚨 CrashDetector: Impact ${linearMag.toStringAsFixed(2)} m/s² | '
        'gyro=${_gyroMagnitude.toStringAsFixed(2)} rad/s | cooldown=$_isInCooldown',
      );

      // --- Step 3: Pocket detection via gyroscope ---
      // When phone is in pocket and bumped, there's often high rotation.
      // Real crash: HIGH linear accel + LOW or HIGH rotation (but very sudden).
      // Pocket walking: MEDIUM linear + MEDIUM rotation (periodic).
      // We use a simple heuristic: if gyro is very high (>5 rad/s), it's likely
      // a deliberate rotation/pocket movement, not a real crash.
      if (_gyroMagnitude > 7.0) {
        debugPrint('🔇 CrashDetector: Suppressed — likely pocket/rotation gesture (gyro=${_gyroMagnitude.toStringAsFixed(2)})');
        return;
      }

      // --- Step 4: Cooldown check ---
      if (_isInCooldown) {
        debugPrint('🔇 CrashDetector: Suppressed — cooldown active');
        return;
      }

      // --- Step 5: Trigger! ---
      _isInCooldown = true;
      onCrashDetected();
      _vibrate();

      // Release cooldown after delay
      Future.delayed(_kCooldown, () => _isInCooldown = false);
    }
  }

  void _vibrate() {
    // Non-blocking — fire and forget
    _doVibrate();
  }

  Future<void> _doVibrate() async {
    try {
      final bool hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(
          pattern: [0, 400, 150, 400, 150, 800],
          intensities: [0, 200, 0, 200, 0, 255],
        );
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }
}
