import 'package:dio/dio.dart';

class ExpenseApi {
  ExpenseApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listExpenses() async {
    final res = await _dio.get('/expenses');
    return (res.data as List).cast();
  }

  Future<List<dynamic>> listExpensesWithFilters(String endpoint) async {
    final res = await _dio.get(endpoint);
    return (res.data as List).cast();
  }

  Future<Map<String, dynamic>> getExpense(int id) async {
    final res = await _dio.get('/expenses/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload) async {
    final res = await _dio.post('/expenses', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> updateExpense(int id, Map<String, dynamic> payload) async {
    await _dio.put('/expenses/$id', data: payload);
  }

  Future<void> deleteExpense(int id) async {
    await _dio.delete('/expenses/$id');
  }

  Future<String> uploadEvidence(int expenseId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/expenses/$expenseId/evidence', data: formData);
    final dto = Map<String, dynamic>.from(res.data as Map);
    return (dto['receiptUrl'] ?? '').toString();
  }
}
