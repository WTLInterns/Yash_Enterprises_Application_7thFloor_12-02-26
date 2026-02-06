import 'package:dio/dio.dart';

class TaskApi {
  TaskApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listTasks() async {
    final res = await _dio.get('/tasks');
    return (res.data as List).cast();
  }

  Future<Map<String, dynamic>> getTask(int id) async {
    final res = await _dio.get('/tasks/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> createTask(Map<String, dynamic> payload) async {
    await _dio.post('/tasks', data: payload);
  }

  Future<void> updateTask(int id, Map<String, dynamic> payload) async {
    await _dio.put('/tasks/$id', data: payload);
  }

  Future<void> updateTaskStatus(int id, String status, int employeeId, {Map<String, String>? headers}) async {
    final options = headers != null ? Options(headers: headers) : null;
    await _dio.put('/tasks/$id/status', 
      data: {
        'status': status,
        'employeeId': employeeId,
      },
      options: options,
    );
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<Response> get(String path) async {
    return await _dio.get(path);
  }
}
