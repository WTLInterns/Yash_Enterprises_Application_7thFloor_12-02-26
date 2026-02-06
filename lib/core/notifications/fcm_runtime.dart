import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notifications_service.dart';
import 'notifications_providers.dart';
import 'fcm_providers.dart';

final fcmRuntimeProvider = Provider<void>((ref) {
  Future<void> handleMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? (message.data['title']?.toString() ?? 'Notification');
    
    // Use formatted message from data payload if available
    String body = message.data['message']?.toString() ?? 
                 message.notification?.body ?? 
                 (message.data['body']?.toString() ?? '');

    await ref.read(notificationsControllerProvider.notifier).add(
          title: title,
          body: body,
          data: Map<String, dynamic>.from(message.data),
        );

    await LocalNotificationsService.instance.init();
    await LocalNotificationsService.instance.show(
      id: Random().nextInt(1 << 30),
      title: title,
      body: body,
      payload: message.data['message']?.toString(), // Pass full message for BigTextStyle
    );
  }

  // Sync FCM token when app starts
  Future<void> syncToken() async {
    try {
      print('🔔 FCM Runtime: Starting token sync...');
      await ref.read(fcmTokenSyncProvider).sync();
      print('🔔 FCM Runtime: Token sync completed');
    } catch (e) {
      print('🔔 FCM Runtime: Token sync failed - $e');
      // Silently fail - token will sync on login
    }
  }

  // Initial token sync
  syncToken();

  final sub1 = FirebaseMessaging.onMessage.listen(handleMessage);

  // Also sync token when it refreshes
  final sub2 = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    syncToken();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
  });
});
