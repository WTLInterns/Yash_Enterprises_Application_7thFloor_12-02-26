import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../data/datasource/expense_api.dart';
import '../../data/repository/expense_repository.dart';

final expenseApiProvider = Provider<ExpenseApi>((ref) {
  return ExpenseApi(ref.watch(dioProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(api: ref.watch(expenseApiProvider));
});

// Provider for selected month (for filtering)
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final expensesProvider = FutureProvider<List<dynamic>>((ref) async {
  final employeeId = await AuthStorage.getEmployeeId();
  final selectedMonth = ref.watch(selectedMonthProvider);
  final month = selectedMonth.month;
  final year = selectedMonth.year;
  
  // If employeeId is 0 (not logged in), get all expenses (fallback)
  final endpoint = employeeId > 0 
      ? "/expenses?employeeId=$employeeId&month=$month&year=$year"
      : "/expenses?month=$month&year=$year";
      
  return ref.watch(expenseRepositoryProvider).getExpensesWithFilters(endpoint);
});
