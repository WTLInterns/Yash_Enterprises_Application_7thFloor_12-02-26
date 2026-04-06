import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../providers/leave_providers.dart';

class LeaveListScreen extends ConsumerWidget {
  const LeaveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(myLeavesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.applyLeave),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: leavesAsync.when(
          data: (leaves) {
            if (leaves.isEmpty) {
              return const Center(child: Text('No leaves found.'));
            }

            return ListView.separated(
              itemCount: leaves.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final l = leaves[i];
                final type = (l['leaveType'] ?? '').toString();
                final from = (l['fromDate'] ?? '').toString();
                final to = (l['toDate'] ?? '').toString();
                final status = (l['status'] ?? '').toString();
                final reason = (l['reason'] ?? '').toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type.isNotEmpty ? type : 'Leave',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _StatusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('From: $from'),
                        Text('To: $to'),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Reason: $reason'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Failed to load leaves')),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toUpperCase();
    Color bg;
    Color fg;

    if (s == 'APPROVED') {
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green;
    } else if (s == 'REJECTED') {
      bg = Colors.red.withOpacity(0.12);
      fg = Colors.red;
    } else {
      bg = Colors.orange.withOpacity(0.12);
      fg = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s.isNotEmpty ? s : '-',
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
