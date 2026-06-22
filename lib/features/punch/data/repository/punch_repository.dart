import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import '../../../../core/storage/secure_session_storage.dart';
import '../../../../core/network/dio_error_handler.dart';
import '../datasource/punch_api.dart';

class ActiveSession {
  final String sessionId;
  final DateTime punchInTime;
  final String status;
  final int? taskId;
  final int elapsedSeconds;

  ActiveSession({
    required this.sessionId,
    required this.punchInTime,
    required this.status,
    this.taskId,
    required this.elapsedSeconds,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      sessionId: json['sessionId'] as String,
      punchInTime: DateTime.parse(json['punchInTime'] as String),
      status: json['status'] as String,
      taskId: json['taskId'] as int?,
      elapsedSeconds: json['elapsedSeconds'] as int,
    );
  }
}

class PunchRepository {
  PunchRepository({
    required PunchApi api,
    required SecureSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final PunchApi _api;
  final SecureSessionStorage _storage;

  Future<Map<String, dynamic>> punchIn({
    required Position position,
    int? taskId,
    String? deviceInfo,
    String? attendanceStatus,
    bool? isHalfDay,
  }) async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null
        ? int.tryParse(employeeIdStr)
        : null;
    if (employeeId == null) throw Exception('Employee ID not found');

    try {
      final response = await _api.punchIn({
        'employeeId': employeeId,
        'punchType': 'IN', // ✅ REQUIRED FIELD - Fixed validation error
        'taskId': taskId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
        'deviceInfo': deviceInfo,
        'attendanceStatus': attendanceStatus,
        'isHalfDay': isHalfDay,
      });
      return response;
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> punchOut({
    required String sessionId,
    required Position position,
    String? deviceInfo,
  }) async {
    try {
      final response = await _api.punchOut({
        'sessionId': sessionId,
        'punchType': 'OUT', // ✅ REQUIRED FIELD - Fixed validation error
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
        'deviceInfo': deviceInfo,
      });

      return response;
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    }
  }

  Future<ActiveSession?> getActiveSession() async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null
        ? int.tryParse(employeeIdStr)
        : null;
    if (employeeId == null) return null;

    final response = await _api.getActiveSession(employeeId);
    if (response == null) return null;

    return ActiveSession.fromJson(response);
  }
}
