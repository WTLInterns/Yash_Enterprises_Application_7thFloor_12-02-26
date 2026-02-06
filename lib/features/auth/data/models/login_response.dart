class LoginResponse {
  LoginResponse({
    required this.token,
    required this.employeeId,
    required this.name,
    required this.role,
    required this.profileImage,
  });

  final String token;
  final String employeeId;
  final String name;
  final String role;
  final String? profileImage;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle both direct fields and nested user object
    final user = json['user'] as Map<String, dynamic>? ?? json;
    
    return LoginResponse(
      token: (json['token'] ?? '').toString(),
      employeeId: (user['id'] ?? user['employeeId'] ?? '').toString(),
      name: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      role: user['roleName']?.toString() ?? user['role']?.toString() ?? '',
      profileImage: user['profileImageUrl']?.toString(),
    );
  }
}
