import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/datasource/attendance_api.dart';
import '../../data/repository/attendance_repository.dart';
import '../../../punch/presentation/providers/punch_providers.dart';

final selectedAttendanceMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(dioProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    api: ref.watch(attendanceApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});

final todayAttendanceProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  return ref.watch(attendanceRepositoryProvider).getTodaySummary();
});

final attendanceMonthlyProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>((
      ref,
      selectedMonth,
    ) async {
      final from = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final to = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
      return ref
          .watch(attendanceRepositoryProvider)
          .getAttendanceByRange(from, to);
    });

// Ensures HomeScreen attendance refreshes immediately after punch IN/OUT.
final attendanceAutoRefreshProvider = Provider<void>((ref) {
  ref.listen<PunchState>(punchControllerProvider, (previous, next) {
    final prevIn = previous?.isPunchedIn;
    if (prevIn != null && prevIn != next.isPunchedIn) {
      ref.invalidate(todayAttendanceProvider);
      final selectedMonth = ref.read(selectedAttendanceMonthProvider);
      ref.invalidate(attendanceMonthlyProvider(selectedMonth));
    }
  });
});
