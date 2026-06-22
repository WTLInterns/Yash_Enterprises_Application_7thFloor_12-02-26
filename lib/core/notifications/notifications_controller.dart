import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_notification_item.dart';
import 'notifications_storage.dart';

class NotificationsState {
  const NotificationsState({required this.items, required this.loading});

  final List<AppNotificationItem> items;
  final bool loading;

  int get unreadCount => items.where((e) => !e.read).length;

  NotificationsState copyWith({
    List<AppNotificationItem>? items,
    bool? loading,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._storage)
    : super(const NotificationsState(items: [], loading: true));

  final NotificationsStorage _storage;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    final items = await _storage.readAll();
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    state = NotificationsState(items: items, loading: false);
  }

  Future<void> add({
    String? id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final effectiveId =
        id ??
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final alreadyExists = state.items.any((e) => e.id == effectiveId);
    if (alreadyExists) {
      print('[NotificationBadge] dedupe_skip id=$effectiveId');
      return;
    }
    final item = AppNotificationItem(
      id: effectiveId,
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      data: data,
      read: false,
    );

    final next = [item, ...state.items];
    state = state.copyWith(items: next, loading: false);
    await _storage.writeAll(next);
  }

  Future<void> markRead(String id) async {
    final next = state.items
        .map((e) => e.id == id ? e.copyWith(read: true) : e)
        .toList();
    state = state.copyWith(items: next);
    await _storage.writeAll(next);
  }

  Future<void> markAllRead() async {
    final next = state.items.map((e) => e.copyWith(read: true)).toList();
    state = state.copyWith(items: next);
    await _storage.writeAll(next);
  }

  Future<void> deleteOne(String id) async {
    final beforeUnread = state.unreadCount;
    final next = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: next);
    await _storage.writeAll(next);
    final afterUnread = state.unreadCount;
    print(
      '[NotificationDelete] deletedId=$id beforeUnread=$beforeUnread afterUnread=$afterUnread remaining=${next.length}',
    );
  }

  Future<void> clear() async {
    final beforeUnread = state.unreadCount;
    state = state.copyWith(items: []);
    await _storage.writeAll([]);
    print(
      '[NotificationDelete] deleteAll beforeUnread=$beforeUnread afterUnread=0 remaining=0',
    );
  }
}
