import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../storage/secure_session_storage.dart';

class FcmTokenSync {
  FcmTokenSync({required Dio dio, required SecureSessionStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureSessionStorage _storage;

  Future<void> sync() async {
    print('🔔 FCM Token Sync: Starting sync...');
    
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('🔔 FCM Token Sync: Permission denied');
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      print('🔔 FCM Token Sync: No token available');
      return;
    }
    
    print('🔔 FCM Token Sync: Got token: ${token.substring(0, 20)}...');

    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null ? int.tryParse(employeeIdStr) : null;
    if (employeeId == null) {
      print('🔔 FCM Token Sync: No employee ID found');
      return;
    }
    
    print('🔔 FCM Token Sync: Sending token for employeeId: $employeeId');

    try {
      await _dio.post(
        '/notifications/token',
        data: {
          'employeeId': employeeId,
          'platform': 'MOBILE',
          'token': token,
        },
      );
      print('🔔 FCM Token Sync: Token sent successfully');
    } catch (e) {
      print('🔔 FCM Token Sync: Failed to send token - $e');
    }
  }
}
