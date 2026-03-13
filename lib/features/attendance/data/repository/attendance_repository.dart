import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/attendance_api.dart';

class AttendanceRepository {
  AttendanceRepository({
    required AttendanceApi api,
    required SecureSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final AttendanceApi _api;
  final SecureSessionStorage _storage;

  Future<Map<String, dynamic>?> getTodaySummary() async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null
        ? int.tryParse(employeeIdStr)
        : null;
    if (employeeId == null) return null;

    return _api.getTodaySummary(employeeId);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByRange(
    DateTime from,
    DateTime to,
  ) async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null
        ? int.tryParse(employeeIdStr)
        : null;
    if (employeeId == null) return const [];

    final fromStr = _formatYmd(from);
    final toStr = _formatYmd(to);
    return _api.getAttendanceByRange(employeeId, fromStr, toStr);
  }

  String _formatYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
