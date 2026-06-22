import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notifications_providers.dart';
import '../../../app/router/route_names.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static IconData _typeIcon(Map<String, dynamic> data) {
    final raw = (data['type'] ?? data['notificationType'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    if (raw == 'TASK_ASSIGN' ||
        raw == 'TASK_ASSIGNED' ||
        raw == 'TASK_ASSIGNED_TO_YOU') {
      return Icons.assignment_outlined;
    }
    if (raw == 'LEAVE_APPROVED') return Icons.check_circle_outline;
    if (raw == 'LEAVE_REJECTED') return Icons.cancel_outlined;
    if (raw == 'LEAVE_APPLY' || raw == 'LEAVE_APPLIED')
      return Icons.pending_actions_outlined;
    return Icons.notifications_none;
  }

  static String _typeLabel(Map<String, dynamic> data) {
    final raw = (data['type'] ?? data['notificationType'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty) return 'GENERAL';
    return raw;
  }

  static Future<void> _confirmDeleteAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete all notifications?'),
          content: const Text(
            'This will remove all notifications from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      print('[NotificationScreen] deleteAll_confirmed');
      await ref.read(notificationsControllerProvider.notifier).clear();
    } else {
      print('[NotificationScreen] deleteAll_cancelled');
    }
  }

  static void _handleTap(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final type = (data['type'] ?? '').toString().trim().toUpperCase();
    final refId = (data['taskId'] ?? data['refId'] ?? data['leaveId'])
        ?.toString();
    print('[NotificationNavigation] type=$type refId=$refId');

    if (type.startsWith('TASK')) {
      // No deep-link route currently exists in app_router; safest fallback is to open the Task tab/screen.
      context.push(RouteNames.shell);
      return;
    }

    if (type.startsWith('LEAVE')) {
      // Leave list is reachable from dashboard; apply screen has a direct route.
      context.push(RouteNames.applyLeave);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No action available for this notification.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Delete all',
            onPressed: state.items.isEmpty
                ? null
                : () => _confirmDeleteAll(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          TextButton(
            onPressed: state.items.isEmpty
                ? null
                : () async {
                    await ref
                        .read(notificationsControllerProvider.notifier)
                        .markAllRead();
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
                final icon = _typeIcon(n.data);
                final typeLabel = _typeLabel(n.data);

                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) async {
                    await ref
                        .read(notificationsControllerProvider.notifier)
                        .deleteOne(n.id);
                  },
                  child: InkWell(
                    onTap: () async {
                      await ref
                          .read(notificationsControllerProvider.notifier)
                          .markRead(n.id);
                      _handleTap(context, ref, n.data);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.read ? Colors.white : const Color(0xFFE7F0FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              fontWeight: n.read
                                                  ? FontWeight.w800
                                                  : FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _fmt(n.receivedAt),
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(
                                              0.45,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      n.body,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.70),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            typeLabel,
                                            style: TextStyle(
                                              color: Colors.black.withOpacity(
                                                0.60,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (!n.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
