abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {}

class SignUpFailure extends SignUpState {
  final String errorMessage;

  SignUpFailure({required this.errorMessage});
}

class SignUpEmailOrPhoneExists extends SignUpState {
  final String message;

  SignUpEmailOrPhoneExists({required this.message});
}
