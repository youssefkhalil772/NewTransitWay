class SignUpRequestBody {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String? avatar;

  SignUpRequestBody({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      if (avatar != null) 'avatar': avatar,
    };
  }
}
