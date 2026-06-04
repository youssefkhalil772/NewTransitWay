import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SosService {
  static Future<String?> triggerSos({
    required String driverId,
    required String busId,
    String? message,
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
        debugPrint('âš ï¸ triggerSos: Location fetch failed: $e');
      }

      final bodyPayload = {
        'action': 'trigger',
        'driver_id': driverId,
        'bus_id': busId,
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        if (message != null && message.isNotEmpty) 'message': message,
      };

      debugPrint('ðŸ“¡ SOS Payload: $bodyPayload');

      try {
        final response = await Supabase.instance.client.functions.invoke(
          'sos-alert',
          body: bodyPayload,
        );

        if (response.status == 200 && response.data != null) {
          final dataMap = response.data as Map<String, dynamic>;
          final alertId =
              dataMap['data']?['alertId'] ??
              dataMap['data']?['alert_id'] ??
              dataMap['alertId'];
          debugPrint('ðŸš¨ SOS Triggered via Function: alertId = $alertId');
          return alertId?.toString();
        }
      } catch (e) {
        debugPrint(
          'âš ï¸ Edge function failed, attempting direct fallback: $e',
        );
      }

      final now = DateTime.now().toUtc().add(const Duration(hours: 3));
      final cairoTime = '${now.toIso8601String().substring(0, 23)}+03:00';

      final fallbackResponse = await Supabase.instance.client
          .from('sos_alerts')
          .insert({
            'driver_id': driverId,
            'bus_id': busId,
            'latitude': position?.latitude ?? 0.0,
            'longitude': position?.longitude ?? 0.0,
            'status': 'Pending',
            if (message != null && message.isNotEmpty) 'message': message,
            'created_at': cairoTime,
          })
          .select('id')
          .maybeSingle();

      final fallbackId = fallbackResponse?['id'];
      debugPrint(
        'ðŸš¨ SOS Triggered via Direct Fallback: alertId = $fallbackId',
      );
      return fallbackId?.toString();
    } catch (e) {
      debugPrint('ðŸ›‘ SOS trigger completely failed: $e');
      return null;
    }
  }

  static Future<void> sendSafe(String alertId) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'sos-alert',
        body: {'action': 'safe', 'alert_id': alertId},
      );
      debugPrint('âœ… SOS Safe action sent successfully via Function');
    } catch (e) {
      debugPrint('âš ï¸ SOS Safe Edge Function failed, using fallback: $e');
      try {
        final now = DateTime.now().toUtc().add(const Duration(hours: 3));
        final cairoTime = '${now.toIso8601String().substring(0, 23)}+03:00';
        await Supabase.instance.client
            .from('sos_alerts')
            .update({'status': 'Safe', 'resolved_at': cairoTime})
            .eq('id', alertId);
        debugPrint('âœ… SOS Safe action sent successfully via Fallback');
      } catch (e2) {
        debugPrint('ðŸ›‘ SOS Safe action completely failed: $e2');
      }
    }
  }

  static Future<void> sendEmergency(String alertId) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'sos-alert',
        body: {'action': 'emergency', 'alert_id': alertId},
      );
      debugPrint('ðŸš¨ SOS Emergency action sent successfully via Function');
    } catch (e) {
      debugPrint(
        'âš ï¸ SOS Emergency Edge Function failed, using fallback: $e',
      );
      try {
        await Supabase.instance.client
            .from('sos_alerts')
            .update({'status': 'Emergency'})
            .eq('id', alertId);
        debugPrint('ðŸš¨ SOS Emergency action sent successfully via Fallback');
      } catch (e2) {
        debugPrint('ðŸ›‘ SOS Emergency action completely failed: $e2');
      }
    }
  }

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

      final response = await Supabase.instance.client
          .from('sos_alerts')
          .insert({
            'driver_id': driverId,
            'bus_id': busId,
            'latitude': position?.latitude ?? 0.0,
            'longitude': position?.longitude ?? 0.0,
            'status': 'Breakdown',
            'message': message,
            'created_at': cairoTime,
          })
          .select('id')
          .maybeSingle();

      final id = response?['id']?.toString();
      debugPrint('ðŸ”§ Breakdown Report sent: alertId=$id, message=$message');
      return id;
    } catch (e) {
      debugPrint('ðŸ›‘ sendBreakdown failed: $e');
      return null;
    }
  }

  static Future<({String driverId, String busId})> loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    String driverId = prefs.getString('driverId') ?? '';
    String busId = prefs.getString('busId') ?? '';

    if (driverId.isEmpty || busId.isEmpty) {
      try {
        final authUser = Supabase.instance.client.auth.currentUser;
        final authId = authUser?.id;
        final email = authUser?.email;

        Map<String, dynamic>? driverData;

        if (authId != null) {
          final res = await Supabase.instance.client
              .from('drivers')
              .select('id, "busId"')
              .eq('id', authId)
              .limit(1);
          if (res.isNotEmpty) driverData = res.first;
        }

        if (driverData == null && email != null) {
          final res = await Supabase.instance.client
              .from('drivers')
              .select('id, "busId"')
              .eq('email', email)
              .limit(1);
          if (res.isNotEmpty) driverData = res.first;
        }

        if (driverData != null) {
          if (driverId.isEmpty && driverData['id'] != null) {
            driverId = driverData['id'].toString();
            await prefs.setString('driverId', driverId);
          }
          if (busId.isEmpty && driverData['busId'] != null) {
            busId = driverData['busId'].toString();
            await prefs.setString('busId', busId);
          }
        }
      } catch (e) {
        debugPrint('âš ï¸ SosService.loadIds DB fallback failed: $e');
      }
    }

    return (driverId: driverId, busId: busId);
  }
}
