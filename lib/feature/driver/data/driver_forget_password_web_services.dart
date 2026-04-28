import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:transite_way/core/networking/api_constants.dart';

class DriverForgetPasswordWebServices {
  
  Future<String?> getEmailByPhone(String phone) async {
    try {
      log("Requesting getEmailByPhone with phone: $phone");
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getDriverEmail}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phone}),
      );
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email'];
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.requestReset}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log("Error in requestReset: $e");
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      log("Requesting verifyOtp for email: $email with code: $otp");
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyCode}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "code": otp,
        }),
      );
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");
      
      return response.statusCode == 200;
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.confirmReset}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");
      
      return response.statusCode == 200;
    } catch (e) {
      log("Error in confirmReset: $e");
      return false;
    }
  }
}
