class LoginResponse {
  LoginResponse({
    required this.token,
    required this.employeeId,
    required this.name,
    required this.role,
    required this.department,
    required this.profileImage,
  });

  final String token;
  final String employeeId;
  final String name;
  final String role;
  final String department;
  final String? profileImage;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle both direct fields and nested user object
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final userDepartment = user['department'];
    final department = userDepartment is Map
        ? (userDepartment['name'] ?? userDepartment['code'] ?? '').toString()
        : (user['departmentName'] ?? user['department'] ?? user['dept'] ?? '')
              .toString();

    return LoginResponse(
      token: (json['token'] ?? '').toString(),
      employeeId: (user['id'] ?? user['employeeId'] ?? '').toString(),
      name: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      role: user['roleName']?.toString() ?? user['role']?.toString() ?? '',
      department: department,
      profileImage: user['profileImageUrl']?.toString(),
    );
  }
}
