import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/networking/supabase_init.dart';
import '../../../core/networking/api_constants.dart';

class ForgetPasswordWebServices {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<String?> getEmailByPhone(String phone) async {
    try {
      final response = await _client.rpc(
        'get_user_email_by_phone',
        params: {'p_phone': phone},
      );

      if (response != null && response is String) {
        return response;
      } else if (response != null &&
          response is Map &&
          response.containsKey('email')) {
        return response['email'] as String?;
      }
      return response?.toString();
    } catch (e) {
      debugPrint("ðŸ›‘ getEmailByPhone Error: $e");
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
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      debugPrint("ðŸ›‘ requestReset Error: $e");
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      return response.user != null;
    } catch (e) {
      debugPrint("ðŸ›‘ verifyOtp Error: $e");
      return false;
    }
  }

  Future<bool> confirmReset(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      debugPrint("ðŸ›‘ confirmReset Error: $e");
      return false;
    }
  }
}
