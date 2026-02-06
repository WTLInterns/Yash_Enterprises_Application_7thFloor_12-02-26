import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: state.items.isEmpty
                ? null
                : () async {
                    await ref.read(notificationsControllerProvider.notifier).markAllRead();
                  },
            child: const Text('Mark all read'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? Center(
                  child: Text(
                    'No notifications',
                    style: TextStyle(color: Colors.black.withOpacity(0.55)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = state.items[i];
                    return InkWell(
                      onTap: () async {
                        await ref.read(notificationsControllerProvider.notifier).markRead(n.id);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.read ? Colors.white : const Color(0xFFE7F0FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Text(
                                  _fmt(n.receivedAt),
                                  style: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.body,
                              style: TextStyle(color: Colors.black.withOpacity(0.70)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
