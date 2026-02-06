import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

@pragma('vm:entry-point')
class BackgroundTrackingService {
  static const _kPunchedInKey = 'punched_in';
  static const _minDistanceMeters = 10.0;

  static Future<void> configure() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: true,
        notificationChannelId: 'yashraj_tracking',
        initialNotificationTitle: 'Yashraj Tracking',
        initialNotificationContent: 'Service is starting...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (!running) {
      await service.startService();
    }
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    Timer? timer;
    Position? lastSent;

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      service.setForegroundNotificationInfo(
        title: 'Yashraj Tracking',
        content: 'Tracking location in background',
      );
    }

    service.on('stop').listen((event) {
      timer?.cancel();
      service.stopSelf();
    });

    final storage = const FlutterSecureStorage();

    // If the service is started (e.g., by boot receiver) but user is not punched-in,
    // stop immediately so we don't run without intent.
    final punchedInRawAtStart = await storage.read(key: _kPunchedInKey);
    final punchedInAtStart = punchedInRawAtStart == '1';
    if (!punchedInAtStart) {
      timer?.cancel();
      service.stopSelf();
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final punchedInRaw = await storage.read(key: _kPunchedInKey);
      final punchedIn = punchedInRaw == '1';
      if (!punchedIn) return;

      final token = await storage.read(key: 'auth_token');
      final employeeIdStr = await storage.read(key: 'employee_id');
      final employeeId = employeeIdStr != null ? int.tryParse(employeeIdStr) : null;
      if (token == null || token.isEmpty || employeeId == null) return;

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (_) {
        return;
      }

      // Only send if moved enough.
      if (lastSent != null) {
        final dist = Geolocator.distanceBetween(
          lastSent!.latitude,
          lastSent!.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (dist < _minDistanceMeters) return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: '${AppConfig.baseUrl}/api',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      try {
        await dio.post('/employee-locations/$employeeId/location', data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'altitude': pos.altitude,
          'accuracy': pos.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'trackingType': 'AUTO',
          'isActive': true,
          'deviceInfo': 'Android ${Platform.operatingSystemVersion}',
        });
        lastSent = pos;
      } catch (e) {
        // Keep background service alive even if network fails.
        print('Location send failed: $e');
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }
}
