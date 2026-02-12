import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleLocationService {
  static final SimpleLocationService _instance = SimpleLocationService._internal();
  factory SimpleLocationService() => _instance;
  SimpleLocationService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  
  bool _isTracking = false;
  Timer? _locationTimer;
  Position? _lastKnownPosition;

  Future<void> initialize() async {
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.notification.request();
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // Get initial position
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Start periodic updates
      _locationTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
        await _updateLocation();
      });

      _isTracking = true;
      print('✅ Location tracking started');
    } catch (e) {
      print('❌ Failed to start tracking: $e');
    }
  }

  Future<void> stopTracking() async {
    _locationTimer?.cancel();
    _isTracking = false;
    print('⏹️ Location tracking stopped');
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastKnownPosition = position;
      await _sendLocationToServer(position);
      
      print('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Failed to update location: $e');
    }
  }

  Future<void> _sendLocationToServer(Position position) async {
    try {
      final employeeId = await _storage.read(key: 'employeeId');
      final token = await _storage.read(key: 'auth_token');

      if (employeeId == null || token == null) {
        print('⚠️ Employee ID or token not found');
        return;
      }

      await _dio.post(
        'http://192.168.1.102:8080/api/employee-locations/$employeeId/location',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'status': 'active',
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Location sent to server');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
    }
  }

  Map<String, dynamic> getTrackingStatus() {
    return {
      'isTracking': _isTracking,
      'lastKnownPosition': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
              'accuracy': _lastKnownPosition!.accuracy,
              'speed': _lastKnownPosition!.speed,
              'heading': _lastKnownPosition!.heading,
            }
          : null,
      'lastUpdateTime': _lastKnownPosition != null 
          ? DateTime.now().toIso8601String() 
          : null,
    };
  }
}
