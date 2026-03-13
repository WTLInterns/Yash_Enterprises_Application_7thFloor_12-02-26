import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:background_fetch/background_fetch.dart' as bg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart' as workmanager;

import '../network/dio_client.dart';

enum RobustBgTickTrigger {
  foregroundServiceTimer,
  workManager,
  backgroundFetch,
  fcm,
  manual,
}

class RobustBgLocationService {
  static final RobustBgLocationService instance =
      RobustBgLocationService._internal();
  RobustBgLocationService._internal();

  static const _kStorageEmployeeId = 'employee_id';
  static const _kStorageAuthToken = 'auth_token';
  static const _kStorageEmployeeName = 'employee_name';
  static const _kStorageEmployeeRole = 'employee_role';
  static const _kStoragePunchedIn = 'punched_in';

  static const _kNotificationChannelId = 'location_tracking';
  static const _kNotificationChannelName = 'Location Tracking';

  static const _kWorkmanagerUniqueName = 'locationUpdate';
  static const _kWorkmanagerTaskName = 'locationUpdateTask';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  late final _dio = createConfiguredDio(
    readToken: () => _storage.read(key: _kStorageAuthToken),
    onUnauthorized: null,
  );

  bool _tickRunning = false;

  bool _initialized = false;

  Position? _lastUploadedPosition;
  DateTime? _lastUploadAt;

  DateTime? _lastMovementAt;
  DateTime? _lastIdleAlertAt;

  DateTime? _backoffUntil;
  int _consecutiveNetworkFailures = 0;

  DateTime? _lastGeocodeAt;
  String? _lastGeocodedAddress;

  double minDistanceMeters = 10.0;
  Duration minUploadInterval = const Duration(minutes: 2);
  Duration idleThreshold = const Duration(minutes: 15);

  Future<void> initialize() async {
    if (_initialized) return;

    await _initializeNotifications();
    await _initializeWorkManager();
    await _initializeBackgroundFetch();
    await _initializeFcmHandlers();

    _initialized = true;
  }

  Future<bool> ensurePrerequisites() async {
    final punchedInRaw = await _storage.read(key: _kStoragePunchedIn);
    final punchedIn = punchedInRaw == '1';
    if (!punchedIn) return false;

    final locationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationEnabled) return false;

    final locStatus = await Permission.location.status;
    if (!locStatus.isGranted) return false;

    if (Platform.isAndroid) {
      final bgLocStatus = await Permission.locationAlways.status;
      if (!bgLocStatus.isGranted) return false;

      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) return false;

      final ignoreBatteryStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (!ignoreBatteryStatus.isGranted) return false;
    }

    final token = await _storage.read(key: _kStorageAuthToken);
    final employeeIdStr = await _storage.read(key: _kStorageEmployeeId);
    final employeeId = employeeIdStr != null
        ? int.tryParse(employeeIdStr)
        : null;
    if (token == null || token.isEmpty || employeeId == null) return false;

    return true;
  }

  Future<void> tick({required RobustBgTickTrigger trigger}) async {
    if (_tickRunning) return;
    _tickRunning = true;

    if (!_initialized) {
      try {
        await initialize();
      } finally {
        // keep tick lock until completion; initialize can throw
      }
    }

    try {
      final now = DateTime.now();
      if (_backoffUntil != null && now.isBefore(_backoffUntil!)) {
        return;
      }

      final ok = await ensurePrerequisites();
      if (!ok) return;

      final token = await _storage.read(key: _kStorageAuthToken);
      final employeeIdStr = await _storage.read(key: _kStorageEmployeeId);
      final employeeId = employeeIdStr != null
          ? int.tryParse(employeeIdStr)
          : null;
      if (token == null || token.isEmpty || employeeId == null) {
        return;
      }

      final position = await acquireLocation();
      if (position == null) return;

      if (!_shouldUpload(now: now, current: position)) {
        _updateMovementState(now: now, current: position);
        return;
      }

      final address = await reverseGeocode(position, now: now);

      await uploadLocation(
        employeeId: employeeId,
        token: token,
        position: position,
        address: address,
      );

      _updateMovementState(now: now, current: position);
      await idleDetection(
        now: now,
        current: position,
        employeeId: employeeId,
        token: token,
      );
    } finally {
      _tickRunning = false;
    }
  }

  Future<Position?> acquireLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> uploadLocation({
    required int employeeId,
    required String token,
    required Position position,
    required String? address,
  }) async {
    try {
      final employeeName = await _storage.read(key: _kStorageEmployeeName);
      final employeeRole = await _storage.read(key: _kStorageEmployeeRole);

      await _dio.post(
        '/employee-locations/$employeeId/location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'altitude': position.altitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': DateTime.now().toIso8601String(),
          'trackingType': 'AUTO',
          'isActive': true,
          'deviceInfo': Platform.isAndroid
              ? 'Android ${Platform.operatingSystemVersion}'
              : Platform.operatingSystem,
          if (address != null) 'address': address,
          if (employeeName != null) 'employeeName': employeeName,
          if (employeeRole != null) 'employeeRole': employeeRole,
        },
      );

      _lastUploadedPosition = position;
      _lastUploadAt = DateTime.now();

      _consecutiveNetworkFailures = 0;
      _backoffUntil = null;
    } catch (_) {
      _consecutiveNetworkFailures++;
      final delaySeconds = _computeBackoffSeconds(_consecutiveNetworkFailures);
      _backoffUntil = DateTime.now().add(Duration(seconds: delaySeconds));
    }
  }

  Future<void> idleDetection({
    required DateTime now,
    required Position current,
    required int employeeId,
    required String token,
  }) async {
    final lastMove = _lastMovementAt;
    if (lastMove == null) return;

    if (now.difference(lastMove) < idleThreshold) return;

    if (_lastIdleAlertAt != null &&
        now.difference(_lastIdleAlertAt!) < idleThreshold) {
      return;
    }

    try {
      final employeeName = await _storage.read(key: _kStorageEmployeeName);

      await _dio.post(
        '/notifications/idle-alert',
        data: {
          'employeeId': employeeId.toString(),
          'employeeName': employeeName,
          'latitude': current.latitude,
          'longitude': current.longitude,
          'idleDuration': '${idleThreshold.inMinutes}+ minutes',
          'timestamp': now.toIso8601String(),
        },
      );

      await _notifications.show(
        999,
        'Idle Alert',
        'You have been idle for ${idleThreshold.inMinutes}+ minutes',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _kNotificationChannelId,
            _kNotificationChannelName,
            channelDescription: 'Location tracking notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

      _lastIdleAlertAt = now;
    } catch (_) {
      // ignore
    }
  }

  Future<String?> reverseGeocode(
    Position position, {
    required DateTime now,
  }) async {
    if (_lastGeocodeAt != null &&
        now.difference(_lastGeocodeAt!) < const Duration(minutes: 5)) {
      return _lastGeocodedAddress;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final street = (p.street ?? '').trim();
      final locality = (p.locality ?? '').trim();
      final admin = (p.administrativeArea ?? '').trim();
      final parts = <String>[
        street,
        locality,
        admin,
      ].where((e) => e.isNotEmpty).toList();
      final addr = parts.isEmpty ? null : parts.join(', ');

      _lastGeocodedAddress = addr;
      _lastGeocodeAt = now;
      return addr;
    } catch (_) {
      return _lastGeocodedAddress;
    }
  }

  bool _shouldUpload({required DateTime now, required Position current}) {
    if (_lastUploadAt != null &&
        now.difference(_lastUploadAt!) < minUploadInterval) {
      return false;
    }

    if (_lastUploadedPosition != null) {
      final dist = Geolocator.distanceBetween(
        _lastUploadedPosition!.latitude,
        _lastUploadedPosition!.longitude,
        current.latitude,
        current.longitude,
      );
      if (dist < minDistanceMeters) return false;
    }

    return true;
  }

  void _updateMovementState({
    required DateTime now,
    required Position current,
  }) {
    if (_lastUploadedPosition == null) {
      _lastMovementAt ??= now;
      return;
    }

    final dist = Geolocator.distanceBetween(
      _lastUploadedPosition!.latitude,
      _lastUploadedPosition!.longitude,
      current.latitude,
      current.longitude,
    );

    if (dist >= 50) {
      _lastMovementAt = now;
    } else {
      _lastMovementAt ??= now;
    }
  }

  int _computeBackoffSeconds(int failures) {
    final capped = failures.clamp(1, 6);
    final base = 10;
    final seconds = base * (1 << (capped - 1));
    return seconds > 300 ? 300 : seconds;
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      _kNotificationChannelId,
      _kNotificationChannelName,
      description: 'Location tracking notifications',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _initializeWorkManager() async {
    try {
      await workmanager.Workmanager().initialize(
        robustBgCallbackDispatcher,
        isInDebugMode: true,
      );

      await workmanager.Workmanager().registerPeriodicTask(
        _kWorkmanagerUniqueName,
        _kWorkmanagerTaskName,
        frequency: const Duration(minutes: 15),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initializeBackgroundFetch() async {
    try {
      await bg.BackgroundFetch.configure(
        bg.BackgroundFetchConfig(
          minimumFetchInterval: 15,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: bg.NetworkType.ANY,
        ),
        (taskId) async {
          try {
            await tick(trigger: RobustBgTickTrigger.backgroundFetch);
          } finally {
            bg.BackgroundFetch.finish(taskId);
          }
        },
        (taskId) async {
          bg.BackgroundFetch.finish(taskId);
        },
      );

      try {
        bg.BackgroundFetch.registerHeadlessTask(
          robustBgBackgroundFetchHeadlessTask,
        );
      } catch (_) {
        // ignore
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initializeFcmHandlers() async {
    try {
      FirebaseMessaging.onMessage.listen(_handleFcmMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmMessage);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _handleFcmMessage(RemoteMessage message) async {
    final command = message.data['command']?.toString();
    if (command == null) return;

    if (command == 'update_location') {
      await tick(trigger: RobustBgTickTrigger.fcm);
    }
  }
}

@pragma('vm:entry-point')
void robustBgCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  workmanager.Workmanager().executeTask((task, inputData) async {
    try {
      if (task == RobustBgLocationService._kWorkmanagerTaskName) {
        await RobustBgLocationService.instance.tick(
          trigger: RobustBgTickTrigger.workManager,
        );
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void robustBgBackgroundFetchHeadlessTask(bg.HeadlessTask task) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    await RobustBgLocationService.instance.tick(
      trigger: RobustBgTickTrigger.backgroundFetch,
    );
  } finally {
    bg.BackgroundFetch.finish(task.taskId);
  }
}
