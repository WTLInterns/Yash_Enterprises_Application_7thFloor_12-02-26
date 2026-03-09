import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart' as workmanager;
import 'package:background_fetch/background_fetch.dart' as bg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.baseUrl}/api',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  DateTime? _lastUpdateTime;

  // Background service configuration
  static const String _serviceTaskId = 'backgroundLocationService';
  static const Duration _locationUpdateInterval = Duration(minutes: 5); // Update every 5 minutes
  static const Duration _idleThreshold = Duration(minutes: 15); // 15 minutes idle threshold

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing Background Location Service...');

      // Initialize notifications
      await _initializeNotifications();

      // Request permissions
      await _requestPermissions();

      // Initialize background service
      await _initializeBackgroundService();

      // Initialize work manager
      await _initializeWorkManager();

      // Initialize background fetch
      await _initializeBackgroundFetch();

      // Start location tracking
      await _startLocationTracking();

      _isInitialized = true;
      print('✅ Background Location Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Background Location Service: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'location_tracking',
      'Location Tracking',
      description: 'Notifications for location tracking',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _requestPermissions() async {
    print('🔐 Requesting permissions...');

    // Location permissions
    final locationPermission = await Permission.location.request();
    if (locationPermission != PermissionStatus.granted) {
      print('❌ Location permission denied');
      throw Exception('Location permission is required');
    }

    // Background location permission (Android)
    if (Platform.isAndroid) {
      final backgroundLocationPermission = await Permission.locationAlways.request();
      if (backgroundLocationPermission != PermissionStatus.granted) {
        print('⚠️ Background location permission not granted');
      }
    }

    // Notification permission
    final notificationPermission = await Permission.notification.request();
    if (notificationPermission != PermissionStatus.granted) {
      print('⚠️ Notification permission not granted');
    }

    // Ignore battery optimization (Android)
    if (Platform.isAndroid) {
      final batteryPermission = await Permission.ignoreBatteryOptimizations.request();
      if (batteryPermission != PermissionStatus.granted) {
        print('⚠️ Battery optimization permission not granted');
      }
    }

    print('✅ Permissions requested');
  }

  Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Location Tracking Active',
        initialNotificationContent: 'Tracking your location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: (ServiceInstance service) async {
          return true;
        },
      ),
    );

    service.startService();
    print('✅ Background service configured');
  }

  Future<void> _initializeWorkManager() async {
    await workmanager.Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    // Schedule periodic location updates
    await workmanager.Workmanager().registerPeriodicTask(
      'locationUpdate',
      'locationUpdateTask',
      frequency: _locationUpdateInterval,
      constraints: workmanager.Constraints(
        networkType: workmanager.NetworkType.connected,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
    );

    print('✅ WorkManager initialized');
  }

  Future<void> _initializeBackgroundFetch() async {
    await bg.BackgroundFetch.configure(
      bg.BackgroundFetchConfig(
        minimumFetchInterval: 15, // 15 minutes
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: bg.NetworkType.ANY,
      ),
      backgroundFetchHeadlessTask,
    );

    print('✅ Background fetch configured');
  }

  Future<void> _startLocationTracking() async {
    print('📍 Starting location tracking...');

    // Get initial position
    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      );
      _lastUpdateTime = DateTime.now();
      
      await _sendLocationToServer(_lastKnownPosition!);
      print('✅ Initial location captured');
    } catch (e) {
      print('⚠️ Failed to get initial location: $e');
    }

    // Start periodic updates
    _locationTimer = Timer.periodic(_locationUpdateInterval, (timer) async {
      await _updateLocation();
    });

    print('✅ Location tracking started');
  }

  Future<void> _updateLocation() async {
    try {
      print('🔄 Updating location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      );

      _lastKnownPosition = position;
      _lastUpdateTime = DateTime.now();

      await _sendLocationToServer(position);
      await _checkForIdleStatus(position);

      print('✅ Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Failed to update location: $e');
    }
  }

  Future<void> _sendLocationToServer(Position position) async {
    try {
      final employeeId = await _storage.read(key: 'employee_id');
      final token = await _storage.read(key: 'auth_token');

      if (employeeId == null || token == null) {
        print('⚠️ Employee ID or token not found');
        return;
      }

      final response = await _dio.post(
        '/employee-locations/$employeeId/location',
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

      print('✅ Location sent to server: ${response.statusCode}');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
    }
  }

  Future<void> _checkForIdleStatus(Position currentPosition) async {
    if (_lastKnownPosition == null || _lastUpdateTime == null) return;

    final distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final timeDiff = DateTime.now().difference(_lastUpdateTime!);

    // Check if employee has been idle for 15+ minutes
    if (distance < 50 && timeDiff > _idleThreshold) { // Less than 50m movement
      await _sendIdleNotification(currentPosition);
    }
  }

  Future<void> _sendIdleNotification(Position position) async {
    try {
      final employeeId = await _storage.read(key: 'employeeId');
      final employeeName = await _storage.read(key: 'employeeName');

      // Send notification to admin
      await _dio.post(
        'http://192.168.1.100:8080/api/notifications/idle-alert',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _storage.read(key: 'auth_token')}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'idleDuration': '15+ minutes',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Show local notification
      await _notifications.show(
        999,
        'Idle Alert',
        'You have been idle for 15+ minutes',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'location_tracking',
            'Location Tracking',
            channelDescription: 'Location tracking notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

      print('🚨 Idle notification sent');
    } catch (e) {
      print('❌ Failed to send idle notification: $e');
    }
  }

  Future<void> stopTracking() async {
    _locationTimer?.cancel();
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    print('⏹️ Location tracking stopped');
  }

  Future<void> startTracking() async {
    await _startLocationTracking();
    print('▶️ Location tracking resumed');
  }

  // Get current tracking status
  Map<String, dynamic> getTrackingStatus() {
    return {
      'isInitialized': _isInitialized,
      'lastKnownPosition': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
              'accuracy': _lastKnownPosition!.accuracy,
              'speed': _lastKnownPosition!.speed,
              'heading': _lastKnownPosition!.heading,
            }
          : null,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'isTracking': _locationTimer?.isActive ?? false,
    };
  }
}

// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Keep the service running
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Send location to server
      // This would use the same logic as _sendLocationToServer
      print('Background location update: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Background location error: $e');
    }
  });
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'locationUpdateTask') {
        // Update location in background
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        // Send to server
        print('WorkManager location update: ${position.latitude}, ${position.longitude}');
      }
      return Future.value(true);
    } catch (e) {
      print('WorkManager error: $e');
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(bg.HeadlessTask task) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // Send to server
    print('Background fetch location update: ${position.latitude}, ${position.longitude}');
    bg.BackgroundFetch.finish(task.taskId);
  } catch (e) {
    print('Background fetch error: $e');
    bg.BackgroundFetch.finish(task.taskId);
  }
}
