import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/core/networking/api_constants.dart';

class DriverForgetPasswordWebServices {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<String?> getEmailByPhone(String phone) async {
    try {
      log("Requesting getEmailByPhone with phone: $phone");
      final response = await _client
          .from(ApiConstants.driversTable)
          .select('email')
          .eq('phone', phone)
          .maybeSingle();

      log("Response: $response");

      if (response != null) {
        return response['email'];
      }
      return null;
    } catch (e) {
      log("Error in getEmailByPhone: $e");
      return null;
    }
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return email;
    return "${name[0]}${'*' * (name.length - 3)}${name.substring(name.length - 2)}@$domain";
  }

  Future<bool> requestReset(String email) async {
    try {
      log("Requesting requestReset with email: $email");
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      log("Error in requestReset: $e");
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      log("Requesting verifyOtp for email: $email with code: $otp");
      final response = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      return response.user != null;
    } catch (e) {
      log("Error in verifyOtp: $e");
      return false;
    }
  }

  Future<bool> confirmReset({
    required String email, 
    required String code, 
    required String newPassword
  }) async {
    try {
      log("Requesting confirmReset for email: $email with code: $code");
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      log("Error in confirmReset: $e");
      return false;
    }
  }
}
