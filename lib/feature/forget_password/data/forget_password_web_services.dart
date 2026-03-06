import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgetPasswordWebServices {
  final String baseUrl = "http://transit-way.runasp.net";

  // البحث عن الإيميل الحقيقي باستخدام رقم الموبايل
  Future<String?> getEmailByPhone(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/get-email-by-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email'];
      }
      return null;
    } catch (e) {
      print("Error in getEmailByPhone: $e");
      return null;
    }
  }

  // دالة إخفاء الإيميل (تظهر أول حرف وآخر رقمين)
  String maskEmail(String email) {
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 3) return email;

    // تأخذ أول حرف + نجوم + آخر رقمين
    return "${name[0]}${'*' * (name.length - 3)}${name.substring(name.length - 2)}@$domain";
  }

  // طلب إرسال الرمز (OTP)
  Future<bool> requestReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/request-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error in requestReset: $e");
      return false;
    }
  }

  // التحقق من الرمز
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"code": otp, "Email": email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // تعيين كلمة المرور الجديدة
  Future<bool> confirmReset(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/confirm-reset'),
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