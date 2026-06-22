import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/datasource/leave_api.dart';
import '../../data/repository/leave_repository.dart';

final leaveApiProvider = Provider<LeaveApi>((ref) {
  return LeaveApi(ref.watch(dioProvider));
});

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(
    api: ref.watch(leaveApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});

final selectedLeaveMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final myLeavesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final selectedMonth = ref.watch(selectedLeaveMonthProvider);
  return ref
      .watch(leaveRepositoryProvider)
      .listMyLeaves(month: selectedMonth.month, year: selectedMonth.year);
});

class ApplyLeaveState {
  const ApplyLeaveState({this.loading = false, this.error});

  final bool loading;
  final String? error;

  ApplyLeaveState copyWith({bool? loading, String? error}) {
    return ApplyLeaveState(loading: loading ?? this.loading, error: error);
  }
}

class ApplyLeaveController extends StateNotifier<ApplyLeaveState> {
  ApplyLeaveController(this._ref) : super(const ApplyLeaveState());

  final Ref _ref;

  Future<void> submit({
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _ref
          .read(leaveRepositoryProvider)
          .applyLeave(
            leaveType: leaveType,
            fromDate: fromDate,
            toDate: toDate,
            reason: reason,
          );
      _ref.invalidate(myLeavesProvider);
      state = state.copyWith(loading: false, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final applyLeaveControllerProvider =
    StateNotifierProvider<ApplyLeaveController, ApplyLeaveState>((ref) {
      return ApplyLeaveController(ref);
    });
