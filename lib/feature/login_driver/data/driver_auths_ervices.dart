import 'dart:convert';
import 'package:http/http.dart' as http;

class DriverAuthServices {
  final String baseUrl = "http://transit-way.runasp.net";

  Future<Map<String, dynamic>> login(String email, String password) async {
    // هنا مستقبلاً هتضيف كود الـ http.post زي اللي عملناه في صفحة اليوزر
    // حالياً هنرجّع قيمة نجاح وهمية للتجربة
    await Future.delayed(const Duration(seconds: 1));
    return {'status': 'success', 'role': 'driver'};
  }
}