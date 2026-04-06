import 'package:dio/dio.dart';

class LeaveApi {
  LeaveApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listMyLeaves() async {
    final res = await _dio.get('/leaves/my');
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }
    return const [];
  }

  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final res = await _dio.post(
      '/leaves',
      data: {
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
