import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles sending SOS emergency alerts instantly via direct Postgres inserts.
class SosService {
  /// Triggers the initial SOS alert when a crash is detected.
  /// Returns the `alertId` if successful, or null on failure.
  static Future<String?> triggerSos({
    required String driverId,
    required String busId,
  }) async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        // Location optional
      }

      final response = await Supabase.instance.client.from('sos_alerts').insert({
        'driver_id': driverId,
        'bus_id': busId,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'status': 'Pending',
      }).select('id').single();

      final alertId = response['id'];
      debugPrint('🚨 SOS Triggered instantly: alertId = $alertId');
      return alertId?.toString();
    } catch (e) {
      debugPrint('🛑 SOS trigger failed: $e');
      return null;
    }
  }

  /// Sends a "Safe" confirmation (driver pressed button).
  static Future<void> sendSafe(String alertId) async {
    try {
      await Supabase.instance.client.from('sos_alerts').update({
        'status': 'Safe',
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', alertId);
      
      debugPrint('✅ SOS Safe action sent successfully');
    } catch (e) {
      debugPrint('🛑 SOS Safe action failed: $e');
      rethrow;
    }
  }

  /// Sends the final "Emergency" action (countdown elapsed).
  static Future<void> sendEmergency(String alertId) async {
    try {
      await Supabase.instance.client.from('sos_alerts').update({
        'status': 'Emergency',
      }).eq('id', alertId);
      
      debugPrint('🚨 SOS Emergency action sent successfully');
    } catch (e) {
      debugPrint('🛑 SOS Emergency action failed: $e');
      rethrow;
    }
  }

  /// Convenience method to load driverId & busId from SharedPreferences
  static Future<({String driverId, String busId})> loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      driverId: prefs.getString('driverId') ?? '',
      busId: prefs.getString('busId') ?? '',
    );
  }
}
