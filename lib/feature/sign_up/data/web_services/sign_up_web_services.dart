import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/networking/api_constants.dart';
import '../models/sign_up_request_body.dart';

class SignUpWebServices {
  Future<http.Response> signUp(SignUpRequestBody signUpRequestBody) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}${ApiConstants.register}"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(signUpRequestBody.toJson()),
    );
    return response;
  }
}
