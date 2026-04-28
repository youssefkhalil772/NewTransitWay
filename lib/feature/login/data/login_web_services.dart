import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/networking/api_constants.dart';

class LoginWebServices {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is String) rethrow;
      throw "Check your internet connection and try again";
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.googleLogin}'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      print("Server Google Login Status: ${response.statusCode}");
      print("Server Google Login Body: ${response.body}");

      return _handleResponse(response);
    } catch (e) {
      if (e is String) rethrow;
      throw "Google authentication error: $e";
    }
  }

  // دالة موحدة للتعامل مع الردود ومنع أخطاء الـ FormatException
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {}; // ارجاع خريطة فارغة لو مفيش بيانات والعملية ناجحة
      } else {
        throw "Server returned error ${response.statusCode} with no message";
      }
    }

    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        if (data['errors'] != null) {
          throw "Validation Error: ${data['errors']}";
        }
        throw data['message'] ?? "Request failed on server";
      }
    } catch (e) {
      throw "Error parsing server response: $e";
    }
  }
}
