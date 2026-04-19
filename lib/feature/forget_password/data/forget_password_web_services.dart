import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/networking/api_constants.dart';

class ForgetPasswordWebServices {
  Future<String?> getEmailByPhone(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getEmail}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'PhoneNumber': phone}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email'];
      }
      return null;
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.requestReset}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyCode}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"code": otp, "Email": email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmReset(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.confirmReset}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
