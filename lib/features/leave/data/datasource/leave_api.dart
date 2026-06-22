import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LeaveApi {
  LeaveApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listMyLeaves({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    if (kDebugMode) {
      final base = _dio.options.baseUrl;
      final uri = Uri.parse(base).replace(
        path: '${Uri.parse(base).path}/leaves/my',
        queryParameters: {
          'employeeId': employeeId,
          'month': month.toString(),
          'year': year.toString(),
        },
      );
      print('===== LEAVE API CALL =====');
      print('employeeId: $employeeId');
      print('month: $month');
      print('year: $year');
      print('GET $uri');
    }

    final res = await _dio.get(
      '/leaves/my',
      queryParameters: {'employeeId': employeeId, 'month': month, 'year': year},
      options: Options(headers: {'X-User-Id': employeeId}),
    );
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }
    return const [];
  }

  Future<Map<String, dynamic>> applyLeave({
    required String employeeId,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final res = await _dio.post(
      '/leaves',
      queryParameters: {'employeeId': employeeId},
      data: {
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateLeave({
    required String employeeId,
    required int leaveId,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final res = await _dio.put(
      '/leaves/$leaveId',
      queryParameters: {'employeeId': employeeId},
      data: {
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> deleteLeave({
    required String employeeId,
    required int leaveId,
  }) async {
    await _dio.delete(
      '/leaves/$leaveId',
      queryParameters: {'employeeId': employeeId},
    );
  }

  Future<Map<String, dynamic>> approveLeave({
    required String employeeId,
    required int leaveId,
  }) async {
    final res = await _dio.put(
      '/leaves/$leaveId/approve',
      queryParameters: {'employeeId': employeeId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> rejectLeave({
    required String employeeId,
    required int leaveId,
  }) async {
    final res = await _dio.put(
      '/leaves/$leaveId/reject',
      queryParameters: {'employeeId': employeeId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
