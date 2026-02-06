import 'package:dio/dio.dart';

class PunchApi {
  PunchApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> punchIn(Map<String, dynamic> payload) async {
    final res = await _dio.post('/punch/in', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> punchOut(Map<String, dynamic> payload) async {
    final res = await _dio.post('/punch/out', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
