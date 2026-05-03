import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transite_way/feature/sign_up/data/models/sign_up_request_body.dart';
import 'package:transite_way/feature/sign_up/domain/repository/sign_up_repository.dart';
import 'package:transite_way/feature/sign_up/presentation/cubit/sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final SignUpRepository _signUpRepository;

  SignUpCubit(this._signUpRepository) : super(SignUpInitial());

  void signUp(SignUpRequestBody signUpRequestBody, File? photo) async {
    emit(SignUpLoading());
    try {
      final response = await _signUpRepository.signUp(signUpRequestBody, photo);

      if (response.containsKey('userId') || response.containsKey('token')) {
        emit(SignUpSuccess());
      } else {
         emit(SignUpFailure(errorMessage: "Registration failed without details"));
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('email') || 
          errorMessage.toLowerCase().contains('phone') || 
          errorMessage.toLowerCase().contains('exist') ||
          errorMessage.toLowerCase().contains('registered')) {
        emit(SignUpEmailOrPhoneExists(message: errorMessage));
      } else {
        emit(SignUpFailure(errorMessage: errorMessage));
      }
    }
  }
}
