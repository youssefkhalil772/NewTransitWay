import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();

  // زيادة الوقت لـ 30 ثانية عشان ندي فرصة للسيرفر يرد في حالة الضغط
  static const Duration _timeoutDuration = Duration(seconds: 30);

  Future<dynamic> get(String endpoint, {Map<String, String>? headers, String? fullUrl}) async {
    final url = fullUrl ?? "${ApiConstants.baseUrl}$endpoint";
    try {
      final response = await _client.get(
        Uri.parse(url), 
        headers: headers
      ).timeout(_timeoutDuration);
      
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception("Connection timeout. The server is taking too long to respond.");
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final url = "${ApiConstants.baseUrl}$endpoint";
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers ?? {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);
      
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception("Request timeout. The server is taking too long to respond.");
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  }
}
