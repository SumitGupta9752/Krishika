class LoginRequest {
  final String? email;
  final String? phone;
  final String password;

  LoginRequest({this.email, this.phone, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'password': password,
    };
  }
}