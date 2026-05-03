import 'dart:io';
import 'package:transite_way/feature/sign_up/data/models/sign_up_request_body.dart';
import 'package:transite_way/feature/sign_up/data/web_services/sign_up_web_services.dart';
import 'package:transite_way/feature/sign_up/domain/repository/sign_up_repository.dart';

class SignUpRepositoryImpl implements SignUpRepository {
  final SignUpWebServices _signUpWebServices;

  SignUpRepositoryImpl(this._signUpWebServices);

  @override
  Future<Map<String, dynamic>> signUp(SignUpRequestBody signUpRequestBody, File? photo) async {
    return await _signUpWebServices.signUp(signUpRequestBody, photo);
  }
}
