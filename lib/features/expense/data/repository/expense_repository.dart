import '../datasource/expense_api.dart';

class ExpenseRepository {
  ExpenseRepository({required ExpenseApi api}) : _api = api;

  final ExpenseApi _api;

  Future<List<dynamic>> getExpenses() => _api.listExpenses();
  Future<Map<String, dynamic>> getExpense(int id) => _api.getExpense(id);
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload) => _api.createExpense(payload);
  Future<void> updateExpense(int id, Map<String, dynamic> payload) => _api.updateExpense(id, payload);
  Future<void> deleteExpense(int id) => _api.deleteExpense(id);
  Future<String> uploadEvidence(int expenseId, String filePath) => _api.uploadEvidence(expenseId, filePath);
}
