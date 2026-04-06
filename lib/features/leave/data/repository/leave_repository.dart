import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/leave_api.dart';

class LeaveRepository {
  LeaveRepository({
    required LeaveApi api,
    required SecureSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final LeaveApi _api;
  final SecureSessionStorage _storage;

  Future<List<Map<String, dynamic>>> listMyLeaves() {
    return _api.listMyLeaves();
  }

  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

    return _api.applyLeave(
      leaveType: leaveType,
      fromDate: _formatYmd(fromDate),
      toDate: _formatYmd(toDate),
      reason: reason,
    );
  }

  String _formatYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
