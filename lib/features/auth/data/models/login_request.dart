class LoginRequest {
  LoginRequest({
    required this.organization,
    required this.email,
    required this.password,
  });

  final String organization;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'organization': organization,
        'email': email,
        'password': password,
      };
}
