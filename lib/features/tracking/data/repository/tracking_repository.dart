import 'package:geolocator/geolocator.dart';

import '../../../../core/storage/secure_session_storage.dart';
import '../datasource/tracking_api.dart';

class TrackingRepository {
  TrackingRepository({required TrackingApi api, required SecureSessionStorage storage})
      : _api = api,
        _storage = storage;

  final TrackingApi _api;
  final SecureSessionStorage _storage;

  Future<void> uploadPosition({
    required Position position,
    String trackingType = 'AUTO',
    String? deviceInfo,
  }) async {
    final employeeIdStr = await _storage.readEmployeeId();
    final employeeId = employeeIdStr != null ? int.tryParse(employeeIdStr) : null;
    if (employeeId == null) return;

    await _api.postLocation({
      'employeeId': employeeId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'trackingType': trackingType,
      'deviceInfo': deviceInfo,
      'isActive': true,
    });
  }
}
