import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasource/expense_api.dart';
import '../../data/repository/expense_repository.dart';

final expenseApiProvider = Provider<ExpenseApi>((ref) {
  return ExpenseApi(ref.watch(dioProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(api: ref.watch(expenseApiProvider));
});

final expensesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getExpenses();
});
