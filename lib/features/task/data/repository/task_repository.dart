import '../datasource/task_api.dart';

class TaskRepository {
  TaskRepository({required TaskApi api}) : _api = api;

  final TaskApi _api;

  Future<List<dynamic>> getTasks() => _api.listTasks();
  Future<Map<String, dynamic>> getTask(int id) => _api.getTask(id);
  Future<void> createTask(Map<String, dynamic> payload) => _api.createTask(payload);
  Future<void> updateTask(int id, Map<String, dynamic> payload) => _api.updateTask(id, payload);
  Future<void> updateTaskStatus(int id, String status, int employeeId, {
    double? latitude,
    double? longitude,
  }) async {
    final options = <String, String>{};
    
    // Add location headers if provided
    if (latitude != null && longitude != null) {
      options['X-Employee-Latitude'] = latitude.toString();
      options['X-Employee-Longitude'] = longitude.toString();
    }
    
    await _api.updateTaskStatus(id, status, employeeId, headers: options);
  }
  Future<void> deleteTask(int id) => _api.deleteTask(id);
  
  Future<Map<String, dynamic>?> getCustomerAddressForTask(int taskId) async {
    try {
      // First get task with customer_address_id
      final taskResponse = await _api.get('/tasks/$taskId');
      final task = taskResponse.data;
      
      if (task['customerAddressId'] == null) {
        return null;
      }
      
      // Then get customer address via customer_address_id
      final addressResponse = await _api.get('/api/customer-addresses/${task['customerAddressId']}');
      return addressResponse.data;
    } catch (e) {
      print('Error fetching customer address: $e');
      return null;
    }
  }
}
