import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles sending SOS emergency alerts instantly via direct Postgres inserts.
class SosService {
  /// Triggers the initial SOS alert when a crash is detected.
  /// Returns the `alertId` if successful, or null on failure.
  /// Triggers the initial SOS alert when a crash is detected via Edge Function.
  /// Returns the `alertId` if successful, or null on failure.
  static Future<String?> triggerSos({
    required String driverId,
    required String busId,
  }) async {
    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        debugPrint('⚠️ triggerSos: Location fetch failed: $e');
      }

      final bodyPayload = {
        'action': 'trigger',
        'driver_id': driverId,
        'bus_id': busId,
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
      };

      debugPrint('📡 SOS Payload: $bodyPayload');

      try {
        final response = await Supabase.instance.client.functions.invoke(
          'sos-alert',
          body: bodyPayload,
        );

        if (response.status == 200 && response.data != null) {
          final dataMap = response.data as Map<String, dynamic>;
          final alertId = dataMap['data']?['alertId'] ?? dataMap['data']?['alert_id'] ?? dataMap['alertId'];
          debugPrint('🚨 SOS Triggered via Function: alertId = $alertId');
          return alertId?.toString();
        }
      } catch (e) {
        debugPrint('⚠️ Edge function failed, attempting direct fallback: $e');
      }

      // Fallback: Direct insert if Edge Function fails or isn't deployed yet
      // Store with Cairo timezone (UTC+3)
      final now = DateTime.now().toUtc().add(const Duration(hours: 3));
      final cairoTime = '${now.toIso8601String().substring(0, 23)}+03:00';

      final fallbackResponse = await Supabase.instance.client.from('sos_alerts').insert({
        'driver_id': driverId,
        'bus_id': busId,
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'status': 'Pending',
        'created_at': cairoTime,
      }).select('id').maybeSingle();

      final fallbackId = fallbackResponse?['id'];
      debugPrint('🚨 SOS Triggered via Direct Fallback: alertId = $fallbackId');
      return fallbackId?.toString();

    } catch (e) {
      debugPrint('🛑 SOS trigger completely failed: $e');
      return null;
    }
  }

  /// Sends a "Safe" confirmation (driver pressed button) via Edge Function.
  static Future<void> sendSafe(String alertId) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'sos-alert',
        body: {
          'action': 'safe',
          'alert_id': alertId,
        },
      );
      debugPrint('✅ SOS Safe action sent successfully via Function');
    } catch (e) {
      debugPrint('⚠️ SOS Safe Edge Function failed, using fallback: $e');
      try {
        final now = DateTime.now().toUtc().add(const Duration(hours: 3));
        final cairoTime = '${now.toIso8601String().substring(0, 23)}+03:00';
        await Supabase.instance.client.from('sos_alerts').update({
          'status': 'Safe',
          'resolved_at': cairoTime,
        }).eq('id', alertId);
        debugPrint('✅ SOS Safe action sent successfully via Fallback');
      } catch (e2) {
        debugPrint('🛑 SOS Safe action completely failed: $e2');
      }
    }
  }

  /// Sends the final "Emergency" action (countdown elapsed) via Edge Function.
  static Future<void> sendEmergency(String alertId) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'sos-alert',
        body: {
          'action': 'emergency',
          'alert_id': alertId,
        },
      );
      debugPrint('🚨 SOS Emergency action sent successfully via Function');
    } catch (e) {
      debugPrint('⚠️ SOS Emergency Edge Function failed, using fallback: $e');
      try {
        await Supabase.instance.client.from('sos_alerts').update({
          'status': 'Emergency',
        }).eq('id', alertId);
        debugPrint('🚨 SOS Emergency action sent successfully via Fallback');
      } catch (e2) {
        debugPrint('🛑 SOS Emergency action completely failed: $e2');
      }
    }
  }

  /// Reports a bus breakdown (non-emergency). Sends message and sets status to 'Breakdown'.
  static Future<String?> sendBreakdown({
    required String driverId,
    required String busId,
    required String message,
  }) async {
    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 2),
          ),
        );
      } catch (_) {}

      final now = DateTime.now().toUtc().add(const Duration(hours: 3));
      final cairoTime = '${now.toIso8601String().substring(0, 23)}+03:00';

      final response = await Supabase.instance.client.from('sos_alerts').insert({
        'driver_id': driverId,
        'bus_id': busId,
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'status': 'Breakdown',
        'message': message,
        'created_at': cairoTime,
      }).select('id').maybeSingle();

      final id = response?['id']?.toString();
      debugPrint('🔧 Breakdown Report sent: alertId=$id, message=$message');
      return id;
    } catch (e) {
      debugPrint('🛑 sendBreakdown failed: $e');
      return null;
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
