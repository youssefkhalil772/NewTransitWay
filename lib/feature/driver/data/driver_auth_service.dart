import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/networking/supabase_init.dart';
import '../../../core/networking/api_constants.dart';

class DriverAuthServices {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw 'Invalid email or password';
      }

      // Fetch driver data — simple select to avoid relationship errors
      final driverData = await _client
          .from(ApiConstants.driversTable)
          .select()
          .eq('email', email)
          .maybeSingle();

      if (driverData == null) {
        throw 'Driver account not found';
      }

      return {
        'token': authResponse.session?.accessToken ?? '',
        ...driverData,
      };
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Server error, please try again later';
    }
  }

  /// Fetches driver data with their assigned bus details (joined).
  Future<Map<String, dynamic>> getDriverData(String driverId) async {
    try {
      final response = await _client
          .from(ApiConstants.driversTable)
          .select()
          .eq('id', driverId)
          .single();

      return response;
    } catch (e) {
      debugPrint("🛑 getDriverData Error: $e");
      if (e is PostgrestException) {
        debugPrint("🛑 Postgrest Error Details: ${e.message} | ${e.details}");
      }
      throw 'Failed to fetch driver data';
    }
  }

  /// Fetches a single bus record directly by its integer ID.
  Future<Map<String, dynamic>?> getBusData(int busId) async {
    try {
      final response = await _client
          .from(ApiConstants.busesTable)
          .select()
          .eq('id', busId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("🛑 getBusData Error: $e");
      return null;
    }
  }

  /// Fetches a bus record by its bus_number (String or int).
  Future<Map<String, dynamic>?> getBusByNumber(String busNumber) async {
    try {
      final response = await _client
          .from(ApiConstants.busesTable)
          .select()
          .eq('bus_number', busNumber)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("🛑 getBusByNumber Error: $e");
      return null;
    }
  }

  /// Fetches a bus record by searching for the driver's ID in the buses table.
  /// Useful if the link is defined in the buses table instead of the drivers table.
  Future<Map<String, dynamic>?> getBusByDriverId(String driverId) async {
    try {
      // Trying only 'driver_id' first as 'assigned_driver_id' failed in logs
      final response = await _client
          .from(ApiConstants.busesTable)
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("🛑 getBusByDriverId Error: $e");
      return null;
    }
  }
}
