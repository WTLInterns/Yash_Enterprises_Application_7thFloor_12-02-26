import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest req) async {
    final res = await _dio.post('/auth/login', data: req.toJson());

    print('===== LOGIN RESPONSE DEBUG =====');
    print(res.data);

    final response = LoginResponse.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );

    print('EmployeeId from login: ${response.employeeId}');
    print('Role from login: ${response.role}');
    print('Department from login: ${response.department}');

    return response;
  }
}
