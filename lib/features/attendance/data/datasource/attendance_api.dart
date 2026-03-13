import 'package:dio/dio.dart';

class AttendanceApi {
  AttendanceApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getTodaySummary(int employeeId) async {
    final res = await _dio.get('/attendance/today/$employeeId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByRange(
    int employeeId,
    String from,
    String to,
  ) async {
    final res = await _dio.get(
      '/attendance/$employeeId',
      queryParameters: {'from': from, 'to': to},
    );
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }
    return const [];
  }
}
