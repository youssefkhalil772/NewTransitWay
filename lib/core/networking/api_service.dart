import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();

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
      throw "Connection timeout. The server is taking too long to respond.";
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
      throw "Request timeout. The server is taking too long to respond.";
    } catch (e) {
      rethrow;
    }
  }

  // دالة جديدة لتحديث البيانات مع صورة (Multipart Request)
  Future<dynamic> putMultipart(String endpoint, {
    Map<String, String>? fields,
    File? file,
    String fileKey = "Photo",
  }) async {
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");
    try {
      var request = http.MultipartRequest('PUT', url);
      
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileKey, file.path));
      }

      var streamedResponse = await request.send().timeout(_timeoutDuration);
      var response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } on TimeoutException {
      throw "Request timeout. The server is taking too long to respond.";
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    final bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    
    if (isSuccess) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      if (response.body.isEmpty) {
        throw "Server Error: ${response.statusCode}";
      }

      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          String msg = errorData['message'] ?? "";
          if (errorData.containsKey('workingHours')) {
            msg += "\n\nWorking Hours: ${errorData['workingHours']}";
          }
          if (msg.isNotEmpty) throw msg;
        }
      } catch (e) {
        if (e is String) rethrow;
      }
      throw response.body;
    }
  }
}
