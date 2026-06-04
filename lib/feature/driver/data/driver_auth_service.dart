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

      final driverData = await _client
          .from(ApiConstants.driversTable)
          .select()
          .eq('email', email)
          .maybeSingle();

      if (driverData != null) {
        final isBanned =
            driverData['is_banned'] == true ||
            driverData['status']?.toString().toLowerCase() == 'banned' ||
            driverData['status']?.toString().toLowerCase() == 'blocked';
        if (isBanned) {
          await _client.auth.signOut();
          throw 'Your account has been banned by the admin.';
        }
      }

      if (driverData == null) {
        throw 'Driver account not found';
      }

      return {'token': authResponse.session?.accessToken ?? '', ...driverData};
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Server error, please try again later';
    }
  }

  Future<Map<String, dynamic>> getDriverData(String driverId) async {
    try {
      var response = await _client
          .from(ApiConstants.driversTable)
          .select()
          .eq('id', driverId)
          .maybeSingle();

      if (response == null) {
        final email = _client.auth.currentUser?.email;
        if (email != null) {
          response = await _client
              .from(ApiConstants.driversTable)
              .select()
              .eq('email', email)
              .maybeSingle();
        }
      }

      return response ?? {};
    } catch (e) {
      debugPrint("ðŸ›‘ getDriverData Error: $e");
      if (e is PostgrestException) {
        debugPrint("ðŸ›‘ Postgrest Error Details: ${e.message} | ${e.details}");
      }
      return {};
    }
  }

  Future<Map<String, dynamic>?> getBusData(int busId) async {
    try {
      final response = await _client
          .from(ApiConstants.busesTable)
          .select()
          .eq('id', busId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("ðŸ›‘ getBusData Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBusByNumber(String busNumber) async {
    try {
      final response = await _client
          .from(ApiConstants.busesTable)
          .select()
          .eq('bus_number', busNumber)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("ðŸ›‘ getBusByNumber Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBusByDriverId(String driverId) async {
    try {
      final response = await _client
          .from(ApiConstants.busesTable)
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("ðŸ›‘ getBusByDriverId Error: $e");
      return null;
    }
  }
}
