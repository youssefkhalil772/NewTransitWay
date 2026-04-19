import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/networking/api_constants.dart';

class DriverAuthServices {
  Future<Map<String, dynamic>> login(String email, String password) async {
    // تم توحيد الـ Base URL هنا أيضاً
    await Future.delayed(const Duration(seconds: 1));
    return {'status': 'success', 'role': 'driver'};
  }
}
