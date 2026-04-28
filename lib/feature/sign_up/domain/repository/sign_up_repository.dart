import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:transite_way/feature/sign_up/data/models/sign_up_request_body.dart';

abstract class SignUpRepository {
  Future<http.Response> signUp(SignUpRequestBody signUpRequestBody, File? photo);
}
