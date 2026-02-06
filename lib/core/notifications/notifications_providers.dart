import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/storage_providers.dart';
import 'notifications_controller.dart';
import 'notifications_storage.dart';

final notificationsStorageProvider = Provider<NotificationsStorage>((ref) {
  final FlutterSecureStorage storage = ref.watch(flutterSecureStorageProvider);
  return NotificationsStorage(storage);
});

final notificationsControllerProvider = StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  final storage = ref.watch(notificationsStorageProvider);
  final ctrl = NotificationsController(storage);
  ctrl.load();
  return ctrl;
});
