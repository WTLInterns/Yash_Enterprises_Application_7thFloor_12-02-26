import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../location/robustbg_location_service.dart';

@pragma('vm:entry-point')
class BackgroundTrackingService {
  static const _kPunchedInKey = 'punched_in';

  static Future<void> configure() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Service is starting...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.dataSync,
        ],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    await RobustBgLocationService.instance.initialize();
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

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      service.setForegroundNotificationInfo(
        title: 'Location Tracking',
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
      try {
        await RobustBgLocationService.instance.tick(
          trigger: RobustBgTickTrigger.foregroundServiceTimer,
        );
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
