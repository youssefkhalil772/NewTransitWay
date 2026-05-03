import 'dart:io';
import 'package:transite_way/feature/sign_up/data/models/sign_up_request_body.dart';

abstract class SignUpRepository {
  Future<Map<String, dynamic>> signUp(SignUpRequestBody signUpRequestBody, File? photo);
}
