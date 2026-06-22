import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/auth_api.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepositoryImpl {
  AuthRepositoryImpl({
    required AuthApi api,
    required SecureSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final AuthApi _api;
  final SecureSessionStorage _storage;

  /// Login and return response (storage write happens in background)
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final resp = await _api.login(
      LoginRequest(email: email, password: password),
    );

    print('===== AUTH REPOSITORY LOGIN =====');
    print('Response received - Employee: ${resp.employeeId}, Role: ${resp.role}, Department: "${resp.department}"');

    // Write to storage asynchronously (non-blocking)
    // State update happens BEFORE this completes
    _storage
        .saveSession(
          token: resp.token,
          employeeId: resp.employeeId,
          name: resp.name,
          role: resp.role,
          department: resp.department, // 🔍 This saves to storage
          profileImage: resp.profileImage,
        )
        .catchError((e) {
          print('⚠️ Storage write error (non-critical): $e');
        });

    print('🔍 Department being saved to storage: "${resp.department}"');
    return resp; // Return immediately, don't wait for storage
  }

  Future<void> logout() => _storage.clear();
}
