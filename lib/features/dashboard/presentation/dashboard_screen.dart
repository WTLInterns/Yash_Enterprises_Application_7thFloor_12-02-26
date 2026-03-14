import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../attendance/presentation/providers/attendance_providers.dart';
import '../../attendance/presentation/widgets/attendance_table_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedMonth = ref.watch(selectedAttendanceMonthProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Attendance Records'),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 8),
        //     child: Row(
        //       children: [
        //         InkWell(
        //           onTap: () {},
        //           borderRadius: BorderRadius.circular(999),
        //           child: Container(
        //             height: 36,
        //             width: 36,
        //             decoration: BoxDecoration(
        //               color: cs.primary,
        //               borderRadius: BorderRadius.circular(999),
        //             ),
        //             child: const Icon(
        //               Icons.list_alt,
        //               color: Colors.white,
        //               size: 20,
        //             ),
        //           ),
        //         ),
        //         const SizedBox(width: 10),
        //         InkWell(
        //           onTap: () {},
        //           borderRadius: BorderRadius.circular(999),
        //           child: Container(
        //             height: 36,
        //             width: 36,
        //             decoration: BoxDecoration(
        //               color: Colors.black,
        //               borderRadius: BorderRadius.circular(999),
        //             ),
        //             child: const Icon(
        //               Icons.location_on_outlined,
        //               color: Colors.white,
        //               size: 20,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          labelColor: cs.primary,
          unselectedLabelColor: Colors.black.withOpacity(0.55),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Attendance'),
            // Tab(text: 'Shift'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _AttendanceTab(
            selectedMonth: selectedMonth,
            onMonthChange: (m) =>
                ref.read(selectedAttendanceMonthProvider.notifier).state = m,
          ),
          // _ShiftTab(),
        ],
      ),
    );
  }

  Widget _monthHeader(ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Month',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, color: cs.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({
    required this.selectedMonth,
    required this.onMonthChange,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final monthText = DateFormat('MMMM yyyy').format(selectedMonth);
    ref.watch(attendanceAutoRefreshProvider);
    final attendanceAsync = ref.watch(attendanceMonthlyProvider(selectedMonth));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _monthHeader(context, cs, monthText),
          const SizedBox(height: 12),
          attendanceAsync.when(
            data: (records) {
              final counts = <String, int>{
                'PRESENT': 0,
                'HALF_DAY': 0,
                'ABSENT': 0,
                'ON_LEAVE': 0,
                'PENDING': 0,
                'HOLIDAY': 0,
                'WEEKLY_OFF': 0,
              };

              for (final r in records) {
                final raw = (r['status']?.toString() ?? '')
                    .trim()
                    .toUpperCase();
                if (counts.containsKey(raw)) {
                  counts[raw] = (counts[raw] ?? 0) + 1;
                }
              }

              return Column(
                children: [
                  Row(
                    children: [
                      _counter('Present', '${counts['PRESENT']}', Colors.green),
                      const SizedBox(width: 10),
                      _counter(
                        'Half Day',
                        '${counts['HALF_DAY']}',
                        Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _counter('Absent', '${counts['ABSENT']}', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _counter('Leave', '${counts['ON_LEAVE']}', Colors.orange),
                      const SizedBox(width: 10),
                      _counter('Pending', '${counts['PENDING']}', Colors.grey),
                      const SizedBox(width: 10),
                      _counter('Holiday', '${counts['HOLIDAY']}', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _counter(
                        'Weekly Off',
                        '${counts['WEEKLY_OFF']}',
                        Colors.blueGrey,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox.shrink()),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: attendanceAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return const Center(
                        child: Text('No attendance found for this month.'),
                      );
                    }
                    return AttendanceTableWidget(records: records);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      const Center(child: Text('Failed to load attendance')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthHeader(BuildContext context, ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
              );
              if (picked == null) return;
              final m = DateTime(picked.year, picked.month);
              onMonthChange(m);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Month',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down, color: cs.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counter(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftTab extends StatelessWidget {
  const _ShiftTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _monthHeader(context, cs, 'January 2026'),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('Total', '0'),
              const SizedBox(width: 10),
              _chip('Assigned', '0'),
              const SizedBox(width: 10),
              _chip('Pending', '0'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'Shift view coming soon',
                    style: TextStyle(color: Colors.black.withOpacity(0.55)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader(BuildContext context, ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Month',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, color: cs.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
