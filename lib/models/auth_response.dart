class AuthResponse {
  final String token;
  final String name;
  final String email;
  final String phone;
  final String userId;

  AuthResponse({
    required this.token,
    required this.name,
    required this.email,
    required this.phone,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Debug logging for JSON structure with better formatting
      print('=== Auth Response JSON ===');
      print('Token: ${json['token']}');
      
      final userObject = json['user'] as Map<String, dynamic>?;
      if (userObject == null) {
        throw FormatException('User object is missing from response');
      }

      // Log user details in a structured way
      print('=== User Details ===');
      print('Name: ${userObject['name']}');
      print('Email: ${userObject['email']}');
      print('Phone: ${userObject['phone']}');
      print('ID: ${userObject['_id']}');
      print('====================');

      // Use string interpolation for null checks
      return AuthResponse(
        token: '${json['token']}',
        name: '${userObject['name']}',
        email: '${userObject['email']}',
        phone: '${userObject['phone']}',
        userId: '${userObject['id']}',
      );
    } catch (e) {
      print('Error parsing AuthResponse: $e');
      // Return an empty response or throw an exception based on your needs
      throw FormatException('Failed to parse authentication response: $e');
    }
  }

  // Debug helper
  @override
  String toString() {
    return 'AuthResponse{token: $token, name: $name, email: $email, phone: $phone, userId: $userId}';
  }
}