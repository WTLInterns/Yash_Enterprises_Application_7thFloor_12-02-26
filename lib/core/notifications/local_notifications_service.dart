import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'unolo_push',
      'UnoLo Notifications',
      description: 'Task and form notifications',
      importance: Importance.high,
    );

    const trackingChannel = AndroidNotificationChannel(
      'location_tracking',
      'Location Tracking',
      description: 'Notifications for location tracking',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(trackingChannel);

    _initialized = true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Use BigTextStyle for multi-line notifications
    final androidDetails = AndroidNotificationDetails(
      'unolo_push',
      'UnoLo Notifications',
      channelDescription: 'Task and form notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: payload != null && payload.contains('\n')
          ? BigTextStyleInformation(payload)
          : null,
    );

    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
