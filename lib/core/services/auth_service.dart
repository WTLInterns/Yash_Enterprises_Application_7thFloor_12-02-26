import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  AuthService._();

  final _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(

      baseUrl: 'http://192.168.1.101:8080/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Initialize Dio with JWT interceptor
  void initializeDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            await logout();
            // Navigate to login screen (you'll need to handle this in your UI)
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['token'] != null) {
        // Store JWT token and user data
        await _secureStorage.write(
          key: 'auth_token',
          value: response.data['token'],
        );
        await _secureStorage.write(
          key: 'user_role',
          value: response.data['role'],
        );
        await _secureStorage.write(
          key: 'user_data',
          value: jsonEncode(response.data['user']),
        );

        return {
          'success': true,
          'user': response.data['user'],
          'role': response.data['role'],
          'token': response.data['token'],
        };
      } else {
        return {'success': false, 'error': 'No token received from server'};
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? e.message ?? 'Login failed',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Logout user
  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_role');
    await _secureStorage.delete(key: 'user_data');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userData = await _secureStorage.read(key: 'user_data');
      return userData != null ? jsonDecode(userData) : null;
    } catch (e) {
      return null;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    return await _secureStorage.read(key: 'user_role');
  }

  // Get JWT token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Check if user has specific role
  Future<bool> hasRole(String requiredRole) async {
    final userRole = await getUserRole();
    return userRole == requiredRole;
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    return await hasRole('ADMIN');
  }

  // Check if user is employee or higher
  Future<bool> isEmployee() async {
    final role = await getUserRole();
    return ['EMPLOYEE', 'ADMIN', 'EXECUTIVE'].contains(role);
  }

  // Get Dio instance for API calls
  Dio get dio => _dio;
}
