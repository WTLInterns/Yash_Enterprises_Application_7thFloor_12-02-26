import 'package:dio/dio.dart';

class TrackingApi {
  TrackingApi(this._dio);

  final Dio _dio;

  Future<void> postLocation(Map<String, dynamic> payload) async {
    await _dio.post('/tracking/location', data: payload);
  }
}
