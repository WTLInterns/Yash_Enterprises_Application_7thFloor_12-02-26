import 'package:dio/dio.dart';

class TaskApi {
  TaskApi(this._dio);

  final Dio _dio;

  static const bool _debugLogs = true;

  void _log(String message) {
    if (!_debugLogs) return;
    print('[TaskApi] $message');
  }

  Future<List<dynamic>> listTasks() async {
    final res = await _dio.get('/tasks');
    return (res.data as List).cast();
  }

  Future<List<dynamic>> getTasksForEmployee(int employeeId) async {
    _log('GET /tasks/employee/$employeeId');
    final res = await _dio.get('/tasks/employee/$employeeId');
    _log('Response status=${res.statusCode}');
    _log('Response runtimeType=${res.data.runtimeType}');
    if (res.data is List) {
      final list = (res.data as List).cast();
      _log('Response length=${list.length}');
      if (list.isNotEmpty) {
        final first = list.first;
        _log('First item runtimeType=${first.runtimeType}');
        if (first is Map) {
          final keys = Map<String, dynamic>.from(first as Map).keys.toList();
          _log('First item keys=$keys');
        }
      }
      return list;
    }
    _log('Unexpected response shape: ${res.data}');
    return (res.data as List).cast();
  }

  Future<List<dynamic>> getTasksForEmployeeAndClient(
    int employeeId,
    int clientId,
  ) async {
    _log('GET /tasks/client/$clientId/employee/$employeeId');
    _log('Params clientId=$clientId employeeId=$employeeId');
    final res = await _dio.get('/tasks/client/$clientId/employee/$employeeId');
    _log('Response status=${res.statusCode}');
    _log('Response runtimeType=${res.data.runtimeType}');
    if (res.data is List) {
      final list = (res.data as List).cast();
      _log('Response length=${list.length}');
      if (list.isNotEmpty) {
        final first = list.first;
        _log('First item runtimeType=${first.runtimeType}');
        if (first is Map) {
          final m = Map<String, dynamic>.from(first as Map);
          _log('First item keys=${m.keys.toList()}');
          _log(
            'First item sample id=${m['id']} taskName=${m['taskName']} startDate=${m['startDate']} scheduledStartTime=${m['scheduledStartTime']}',
          );
        }
      }
      return list;
    }

    _log('Unexpected response shape: ${res.data}');
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
