import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/auth_api.dart';
import '../models/login_request.dart';

class AuthRepositoryImpl {
  AuthRepositoryImpl({
    required AuthApi api,
    required SecureSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final AuthApi _api;
  final SecureSessionStorage _storage;

  Future<void> login({
    required String organization,
    required String email,
    required String password,
  }) async {
    final resp = await _api.login(
      LoginRequest(
        organization: organization,
        email: email,
        password: password,
      ),
    );

    await _storage.saveSession(
      token: resp.token,
      employeeId: resp.employeeId,
      name: resp.name,
      role: resp.role,
      department: resp.department,
      profileImage: resp.profileImage,
    );
  }

  Future<void> logout() => _storage.clear();
}
