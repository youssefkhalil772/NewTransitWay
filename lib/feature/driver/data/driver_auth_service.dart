import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/networking/api_constants.dart';

class DriverAuthServices {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.loginDriver}");
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final isJson = response.headers['content-type']?.contains('application/json') ?? false;

      if (isJson) {
        final responseBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return responseBody;
        } else {
          throw responseBody['message'] ?? 'Invalid credentials or server error';
        }
      } else {
        if (response.statusCode == 401) {
          throw 'Invalid email or password';
        }
        throw 'Server error, please try again later';
      }
    } catch (e) {
      if (e is FormatException) {
        throw 'Unexpected response format from server';
      }
      rethrow;
    }
  }

  // دالة جديدة لجلب بيانات السائق بالتفصيل
  Future<Map<String, dynamic>> getDriverData(int driverId) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.getDriver(driverId)}");
    try {
      final response = await http.get(url, headers: {'accept': '*/*'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw 'Failed to fetch driver data';
      }
    } catch (e) {
      rethrow;
    }
  }
}
