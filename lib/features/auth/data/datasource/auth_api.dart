import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest req) async {
    final res = await _dio.post('/auth/login', data: req.toJson());

    print('===== LOGIN API RESPONSE RECEIVED =====');
    print('Raw Backend Response:');
    print(res.data);
    print('Response Type: ${res.data.runtimeType}');
    
    final response = LoginResponse.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );

    print('===== LOGIN RESPONSE MODEL PARSED =====');
    print('Employee ID: "${response.employeeId}"');
    print('Role: "${response.role}"');
    print('Department: "${response.department}"');
    print('Name: "${response.name}"');
    print('Token present: ${response.token.isNotEmpty}');
    
    // Check if department is null/empty after parsing
    if (response.department.isEmpty) {
      print('🚨 CRITICAL: Department is EMPTY after parsing!');
      print('Raw user data for department analysis:');
      final user = res.data['user'] as Map<String, dynamic>? ?? res.data;
      print('user.department: ${user['department']}');
      print('user.departmentName: ${user['departmentName']}');
      print('user.dept: ${user['dept']}');
      if (user['department'] is Map) {
        final deptMap = user['department'] as Map;
        print('user.department.name: ${deptMap['name']}');
        print('user.department.code: ${deptMap['code']}');
      }
    }

    return response;
  }
}
