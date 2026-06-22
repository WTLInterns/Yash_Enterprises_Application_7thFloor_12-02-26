import 'package:dio/dio.dart';

import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/leave_api.dart';

class LeaveRepository {
  LeaveRepository({
    required LeaveApi api,
    required SecureSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final LeaveApi _api;
  final SecureSessionStorage _storage;

  Future<List<Map<String, dynamic>>> listMyLeaves({
    required int month,
    required int year,
  }) async {
    final employeeIdRaw = await _storage.readEmployeeId();
    final employeeId = employeeIdRaw?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      // Employee data missing in storage is not an authentication failure.
      // We still attempt the API call (with empty employeeId) to avoid
      // misleading "Please login again" messaging and to surface backend errors.
      // ignore: avoid_print
      print(
        'LeaveRepository.listMyLeaves: employeeId missing in secure storage',
      );
    }

    try {
      return await _api.listMyLeaves(
        employeeId: employeeId ?? '',
        month: month,
        year: year,
      );
    } on DioException catch (e) {
      if (employeeId == null || employeeId.isEmpty) {
        throw Exception('User data missing');
      }
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          throw Exception(message);
        }
      }
      throw Exception('Failed to load leaves');
    }
  }

  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    final employeeIdRaw = await _storage.readEmployeeId();
    final employeeId = employeeIdRaw?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('User data missing');
    }
    return _api.applyLeave(
      employeeId: employeeId,
      leaveType: leaveType,
      fromDate: _formatYmd(fromDate),
      toDate: _formatYmd(toDate),
      reason: reason,
    );
  }

  Future<Map<String, dynamic>> updateLeave({
    required int leaveId,
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    final employeeIdRaw = await _storage.readEmployeeId();
    final employeeId = employeeIdRaw?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('User data missing');
    }
    return _api.updateLeave(
      employeeId: employeeId,
      leaveId: leaveId,
      leaveType: leaveType,
      fromDate: _formatYmd(fromDate),
      toDate: _formatYmd(toDate),
      reason: reason,
    );
  }

  Future<void> deleteLeave({required int leaveId}) async {
    final employeeIdRaw = await _storage.readEmployeeId();
    final employeeId = employeeIdRaw?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('User data missing');
    }
    await _api.deleteLeave(employeeId: employeeId, leaveId: leaveId);
  }

  Future<Map<String, dynamic>> approveLeave({required int leaveId}) async {
    final employeeIdRaw = await _storage.readEmployeeId();
    final employeeId = employeeIdRaw?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('User data missing');
    }
    return _api.approveLeave(employeeId: employeeId, leaveId: leaveId);
  }

  Future<Map<String, dynamic>> rejectLeave({required int leaveId}) async {
    final employeeIdRaw = await _storage.readEmployeeId();
    final employeeId = employeeIdRaw?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      throw Exception('User data missing');
    }
    return _api.rejectLeave(employeeId: employeeId, leaveId: leaveId);
  }

  String _formatYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
