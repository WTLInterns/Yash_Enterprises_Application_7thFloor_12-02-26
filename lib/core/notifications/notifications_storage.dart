import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_notification_item.dart';

class NotificationsStorage {
  NotificationsStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kKey = 'in_app_notifications';

  Future<List<AppNotificationItem>> readAll() async {
    final raw = await _storage.read(key: _kKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => AppNotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> writeAll(List<AppNotificationItem> items) async {
    final payload = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.write(key: _kKey, value: payload);
  }
}
