import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:background_fetch/background_fetch.dart' as bg;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Robust Location Service - Works in all scenarios:
/// - App removed from recent tabs
/// - Phone locked
/// - Phone screen off
/// - App in background
/// - Until phone is switched off
class RobustLocationService {
  static final RobustLocationService _instance = RobustLocationService._internal();
  factory RobustLocationService() => _instance;
  RobustLocationService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  bool _isTracking = false;
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  DateTime? _lastUpdateTime;
  int _consecutiveFailures = 0;

  // Configuration
  static const Duration _locationUpdateInterval = Duration(minutes: 2); // 2 minutes for better tracking
  static const Duration _idleThreshold = Duration(minutes: 15);
  static const int _maxConsecutiveFailures = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing Robust Location Service...');

      // Initialize notifications
      await _initializeNotifications();

      // Request all necessary permissions
      await _requestPermissions();

      // Initialize multiple tracking mechanisms
      await _initializeBackgroundService();
      await _initializeBackgroundFetch();

      try {
        bg.BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
      } catch (_) {
        // ignore
      }

      // Set up Firebase messaging for remote commands
      await _setupFirebaseMessaging();

      _isInitialized = true;
      print('✅ Robust Location Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Robust Location Service: $e');
      rethrow;
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'location_tracking',
      'Location Tracking',
      description: 'Robust location tracking notifications',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _requestPermissions() async {
    print('🔐 Requesting comprehensive permissions...');

    // Core location permissions
    final locationPermission = await Permission.location.request();
    if (locationPermission != PermissionStatus.granted) {
      throw Exception('Location permission is required');
    }

    // Background location (Android)
    if (Platform.isAndroid) {
      final backgroundLocationPermission = await Permission.locationAlways.request();
      if (backgroundLocationPermission != PermissionStatus.granted) {
        print('⚠️ Background location permission not granted - tracking may be limited');
      }
    }

    // Notification permissions
    final notificationPermission = await Permission.notification.request();
    if (notificationPermission != PermissionStatus.granted) {
      print('⚠️ Notification permission not granted');
    }

    // Battery optimization (Android)
    if (Platform.isAndroid) {
      final batteryPermission = await Permission.ignoreBatteryOptimizations.request();
      if (batteryPermission != PermissionStatus.granted) {
        print('⚠️ Battery optimization permission not granted');
      }
    }

    // System alert window (Android - for overlay)
    if (Platform.isAndroid) {
      final systemAlertPermission = await Permission.systemAlertWindow.request();
      if (systemAlertPermission != PermissionStatus.granted) {
        print('⚠️ System alert permission not granted');
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
        initialNotificationContent: 'Robust tracking enabled - works even when app is closed',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location, AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: (ServiceInstance service) async {
          return true;
        },
      ),
    );

    // ⚠️ Check if service is already running before starting
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      print('✅ Background service started');
    } else {
      print('✅ Background service already running');
    }
  }

  Future<void> _initializeBackgroundFetch() async {
    try {
      await bg.BackgroundFetch.configure(
        bg.BackgroundFetchConfig(
          minimumFetchInterval: 15, // 15 minutes
          stopOnTerminate: false, // Continue after app termination
          enableHeadless: true, // Run in headless mode
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: bg.NetworkType.ANY,
        ),
        (taskId) async {
          try {
            await _updateLocation();
          } finally {
            bg.BackgroundFetch.finish(taskId);
          }
        },
        (taskId) async {
          bg.BackgroundFetch.finish(taskId);
        },
      );

      print('✅ Background fetch configured');
    } catch (e) {
      print('⚠️ Background fetch configuration failed: $e');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Handle remote messages for remote control
      FirebaseMessaging.onMessage.listen(_handleFirebaseMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleFirebaseMessage);
      
      // Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      
      print('✅ Firebase messaging configured');
    } catch (e) {
      print('⚠️ Firebase messaging setup failed: $e');
    }
  }

  Future<void> _handleFirebaseMessage(RemoteMessage message) async {
    print('📨 Received Firebase message: ${message.messageId}');
    
    // Handle remote commands like "start_tracking", "stop_tracking"
    final command = message.data['command'];
    if (command != null) {
      switch (command) {
        case 'start_tracking':
          await startTracking();
          break;
        case 'stop_tracking':
          await stopTracking();
          break;
        case 'update_location':
          await _updateLocation();
          break;
      }
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      print('📍 Starting robust location tracking...');

      // Get initial position
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      );
      _lastUpdateTime = DateTime.now();
      
      await _sendLocationToServer(_lastKnownPosition!);
      
      // Start multiple tracking mechanisms
      _startPeriodicUpdates();
      _isTracking = true;
      
      // Show persistent notification
      await _showTrackingNotification('Location tracking started');
      
      print('✅ Robust location tracking started');
    } catch (e) {
      print('❌ Failed to start tracking: $e');
      rethrow;
    }
  }

  Future<void> _startPeriodicUpdates() async {
    // Primary timer for when app is active
    _locationTimer = Timer.periodic(_locationUpdateInterval, (timer) async {
      await _updateLocation();
    });

    // Also update immediately
    await _updateLocation();
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
      _consecutiveFailures = 0; // Reset failure counter

      await _sendLocationToServer(position);
      await _checkForIdleStatus(position);

      print('✅ Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Failed to update location: $e');
      _consecutiveFailures++;
      
      // If too many failures, try to restart tracking
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        print('⚠️ Too many consecutive failures, attempting restart...');
        await _restartTracking();
      }
    }
  }

  Future<void> _restartTracking() async {
    try {
      print('🔄 Restarting location tracking...');
      _consecutiveFailures = 0;
      
      // Stop and restart
      _locationTimer?.cancel();
      await Future.delayed(Duration(seconds: 5));
      await _startPeriodicUpdates();
      
      print('✅ Location tracking restarted');
    } catch (e) {
      print('❌ Failed to restart tracking: $e');
    }
  }

  Future<void> _sendLocationToServer(Position position) async {
    try {
      final employeeId = await _storage.read(key: 'employee_id');
      final token = await _storage.read(key: 'auth_token');
      final employeeName = await _storage.read(key: 'employee_name');
      final employeeRole = await _storage.read(key: 'employee_role');

      if (employeeId == null || token == null) {
        print('⚠️ Employee ID or token not found');
        return;
      }

      String address = 'Unknown address';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = (p.street ?? '').trim();
          final locality = (p.locality ?? '').trim();
          final admin = (p.administrativeArea ?? '').trim();
          final parts = [street, locality, admin].where((x) => x.isNotEmpty).toList();
          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        // ignore
      }

      print('══════════════════════════════════════');
      print('📱 FLUTTER LOCATION EVENT');
      print('👤 ${(employeeName ?? '').toString()} (${(employeeRole ?? '').toString()}) ID=$employeeId');
      print('📍 ${position.latitude}, ${position.longitude}');
      print('🏠 $address');
      print('⏱ ${DateTime.now()}');
      print('══════════════════════════════════════');

      print('📍 Sending location to server: ${position.latitude}, ${position.longitude}');
      print('👤 Employee ID: $employeeId');
      print('🌐 URL: http://192.168.1.102:8080/api/employee-locations/$employeeId/location');

      final response = await _dio.post(
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
          'trackingType': 'AUTO',
          'deviceInfo': Platform.isAndroid
              ? 'Android ${Platform.operatingSystemVersion}'
              : Platform.operatingSystem,
          'address': address,
        },
      );

      print('✅ Location sent to server: ${response.statusCode}');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
      // Don't rethrow - allow tracking to continue
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
    if (distance < 50 && timeDiff > _idleThreshold) {
      await _sendIdleNotification(currentPosition);
    }
  }

  Future<void> _sendIdleNotification(Position position) async {
    try {
      final employeeId = await _storage.read(key: 'employee_id');
      final employeeName = await _storage.read(key: 'employee_name');

      // Send notification to admin
      await _dio.post(
        'http://192.168.1.102:8080/api/employee-locations/idle-alert',
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
      await _showTrackingNotification('You have been idle for 15+ minutes');

      print('🚨 Idle notification sent');
    } catch (e) {
      print('❌ Failed to send idle notification: $e');
    }
  }

  Future<void> _showTrackingNotification(String message) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Location Tracking',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'location_tracking',
          'Location Tracking',
          channelDescription: 'Robust location tracking notifications',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true, // Make it persistent
          autoCancel: false,
        ),
      ),
    );
  }

  Future<void> stopTracking() async {
    _locationTimer?.cancel();
    _isTracking = false;
    
    // Cancel persistent notification
    await _notifications.cancelAll();
    
    print('⏹️ Robust location tracking stopped');
  }

  Map<String, dynamic> getTrackingStatus() {
    return {
      'isInitialized': _isInitialized,
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
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'consecutiveFailures': _consecutiveFailures,
      'trackingMethod': 'robust_background',
    };
  }
}

// Background service entry point - runs even when app is closed
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    // 🔥 MUST be FIRST - within 5 seconds
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: 'Location Tracking Active',
      content: 'Tracking location in background',
    );

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // ⏳ Delay heavy work slightly
  Future.delayed(const Duration(seconds: 1), () {
    _startBackgroundLogic();
  });
}

void _startBackgroundLogic() {
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Send location to server using same logic as main service
      print('Background location update: ${position.latitude}, ${position.longitude}');
      
      // 📍 Send to server!
      await RobustLocationService()._sendLocationToServer(position);
      
    } catch (e) {
      print('Background location error: $e');
    }
  });
}

// Background fetch headless task - runs when app is terminated
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(bg.HeadlessTask task) async {
  try {
    print('Background fetch task started');
    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // Send to server
    print('Background fetch location update: ${position.latitude}, ${position.longitude}');

    await RobustLocationService()._sendLocationToServer(position);

    bg.BackgroundFetch.finish(task.taskId);
  } catch (e) {
    print('Background fetch error: $e');
    bg.BackgroundFetch.finish(task.taskId);
  }
}

// Firebase background message handler
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('Firebase background message: ${message.messageId}');
  // Handle remote commands even when app is completely closed
}
