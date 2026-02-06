import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest req) async {
    final res = await _dio.post('/auth/login', data: req.toJson());
    print('🔐 Login Response: ${res.data}');
    final response = LoginResponse.fromJson(Map<String, dynamic>.from(res.data as Map));
    print('🔐 Parsed LoginResponse - employeeId: ${response.employeeId}, name: ${response.name}');
    return response;
  }
}
