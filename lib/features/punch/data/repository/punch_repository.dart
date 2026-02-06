import 'package:geolocator/geolocator.dart';

import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/punch_api.dart';

class PunchRepository {
  PunchRepository({required PunchApi api, required SecureSessionStorage storage})
      : _api = api,
        _storage = storage;

  final PunchApi _api;
  final SecureSessionStorage _storage;

  Future<void> punchIn({required Position position, String? deviceInfo}) async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null ? int.tryParse(employeeIdStr) : null;
    if (employeeId == null) return;

    await _api.punchIn({
      'employeeId': employeeId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
      'punchTime': DateTime.now().toIso8601String(),
      'deviceInfo': deviceInfo,
    });
  }

  Future<void> punchOut({required Position position, String? deviceInfo}) async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null ? int.tryParse(employeeIdStr) : null;
    if (employeeId == null) return;

    await _api.punchOut({
      'employeeId': employeeId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
      'punchTime': DateTime.now().toIso8601String(),
      'deviceInfo': deviceInfo,
    });
  }
}
