class SignupRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String? id; // Add ID field

  SignupRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.role = 'user',
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'id': id,
    };
  }
}