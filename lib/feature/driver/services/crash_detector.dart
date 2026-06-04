import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

const double _kCrashThreshold = 45.0;

const Duration _kCooldown = Duration(seconds: 5);

class CrashDetector {
  final VoidCallback onCrashDetected;

  CrashDetector({required this.onCrashDetected});

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  bool _isInCooldown = false;

  double _gx = 0, _gy = 0, _gz = 9.8;

  double _gyroMagnitude = 0;

  void start() {
    _accelSub?.cancel();
    _gyroSub?.cancel();

    try {
      _gyroSub =
          gyroscopeEventStream(
            samplingPeriod: const Duration(milliseconds: 100),
          ).listen((e) {
            _gyroMagnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          });
    } catch (e) {
      debugPrint('âš ï¸ CrashDetector: Gyroscope not available: $e');
    }

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(_onAccelEvent);

    debugPrint(
      'ðŸ’¡ CrashDetector: started (threshold=${_kCrashThreshold}m/sÂ²)',
    );
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    debugPrint('ðŸ’¡ CrashDetector: stopped');
  }

  void _onAccelEvent(AccelerometerEvent e) {
    const double alpha = 0.8;
    _gx = alpha * _gx + (1 - alpha) * e.x;
    _gy = alpha * _gy + (1 - alpha) * e.y;
    _gz = alpha * _gz + (1 - alpha) * e.z;

    final double lx = e.x - _gx;
    final double ly = e.y - _gy;
    final double lz = e.z - _gz;
    final double linearMag = sqrt(lx * lx + ly * ly + lz * lz);

    if (linearMag >= _kCrashThreshold) {
      debugPrint(
        'ðŸš¨ CrashDetector: Impact ${linearMag.toStringAsFixed(2)} m/sÂ² | '
        'gyro=${_gyroMagnitude.toStringAsFixed(2)} rad/s | cooldown=$_isInCooldown',
      );

      if (_gyroMagnitude > 15.0) {
        debugPrint(
          'ðŸ”‡ CrashDetector: Suppressed â€” likely pocket/rotation gesture (gyro=${_gyroMagnitude.toStringAsFixed(2)})',
        );
        return;
      }

      if (_isInCooldown) {
        debugPrint('ðŸ”‡ CrashDetector: Suppressed â€” cooldown active');
        return;
      }

      _isInCooldown = true;
      onCrashDetected();
      _vibrate();

      Future.delayed(_kCooldown, () => _isInCooldown = false);
    }
  }

  void _vibrate() {
    _doVibrate();
  }

  Future<void> _doVibrate() async {
    try {
      final bool hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(
          pattern: [
            0,
            200,
            100,
            200,
            100,
            200,
            200,
            600,
            200,
            600,
            200,
            600,
            200,
            200,
            100,
            200,
            100,
            200,
          ],
          intensities: [
            0,
            255,
            0,
            255,
            0,
            255,
            0,
            255,
            0,
            255,
            0,
            255,
            0,
            255,
            0,
            255,
            0,
            255,
          ],
        );
      } else {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }
}
