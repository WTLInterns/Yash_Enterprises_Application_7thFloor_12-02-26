import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'core/location/robustbg_location_service.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/tracking/background_tracking_service.dart';
import 'core/websocket/websocket_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  final command = message.data['command']?.toString();
  if (command == 'update_location') {
    await RobustBgLocationService.instance.tick(
      trigger: RobustBgTickTrigger.fcm,
    );
  }

  final title =
      message.notification?.title ??
      (message.data['title']?.toString() ?? 'Notification');
  final body =
      message.notification?.body ?? (message.data['body']?.toString() ?? '');

  // Persist to the same local list used by the in-app bell.
  const storage = FlutterSecureStorage();
  const key = 'in_app_notifications';
  final existingRaw = await storage.read(key: key);

  List<dynamic> list;
  try {
    final decoded = existingRaw != null && existingRaw.isNotEmpty
        ? jsonDecode(existingRaw)
        : [];
    list = decoded is List ? decoded : <dynamic>[];
  } catch (_) {
    list = <dynamic>[];
  }

  final item = {
    'id': '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
    'title': title,
    'body': body,
    'receivedAt': DateTime.now().toIso8601String(),
    'data': message.data,
    'read': false,
  };

  list.insert(0, item);
  await storage.write(key: key, value: jsonEncode(list));

  // Also show a system notification.
  await LocalNotificationsService.instance.init();
  await LocalNotificationsService.instance.show(
    id: Random().nextInt(1 << 30),
    title: title,
    body: body,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await LocalNotificationsService.instance.init();

  // Configure background tracking service (do not auto-start here).
  await BackgroundTrackingService.configure();

  runApp(const ProviderScope(child: UnoloApp()));

  // Defer non-critical network connections until after first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WebSocketService.instance.connect();
  });
}
