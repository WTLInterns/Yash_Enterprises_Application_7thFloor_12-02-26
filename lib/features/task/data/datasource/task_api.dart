import 'package:dio/dio.dart';

class TaskApi {
  TaskApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listTasks() async {
    final res = await _dio.get('/tasks');
    return (res.data as List).cast();
  }

  Future<List<dynamic>> getTasksForEmployee(int employeeId) async {
    final res = await _dio.get('/tasks/employee/$employeeId');
    return (res.data as List).cast();
  }

  Future<List<dynamic>> getTasksForEmployeeAndClient(
    int employeeId,
    int clientId,
  ) async {
    final res = await _dio.get('/tasks/client/$clientId/employee/$employeeId');
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

  Future<void> updateTaskStatus(
    int id,
    String status,
    int employeeId, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final options = Options();
      if (latitude != null && longitude != null) {
        options.headers = {
          'X-User-Role': 'EMPLOYEE',
          'X-Employee-Latitude': latitude.toString(),
          'X-Employee-Longitude': longitude.toString(),
        };
      } else {
        options.headers = {'X-User-Role': 'EMPLOYEE'};
      }

      await _dio.put(
        '/tasks/$id/status',
        data: {'status': status, 'employeeId': employeeId},
        options: options,
      );
    } on DioException catch (e) {
      // Simple error handling - NO OVERENGINEERING
      final message = _extractErrorMessage(e);
      print('Task status update failed: $message');
      rethrow;
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  // Simple error extraction - CLEAN & PRACTICAL
  String _extractErrorMessage(DioException e) {
    final response = e.response;
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      // Try new error code format first
      if (data.containsKey('error')) {
        return data['error'] as String? ?? 'Update failed';
      }

      // Fallback to legacy format
      if (data.containsKey('message')) {
        return data['message'] as String? ?? 'Update failed';
      }
    }

    // Fallback to HTTP status
    return 'Update failed (${response?.statusCode ?? 'unknown'})';
  }
}
