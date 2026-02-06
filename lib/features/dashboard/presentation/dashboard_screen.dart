import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.list_alt, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          labelColor: cs.primary,
          unselectedLabelColor: Colors.black.withOpacity(0.55),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'Shift'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _AttendanceTab(focusedDay: _focusedDay, onFocus: (d) => setState(() => _focusedDay = d)),
          _ShiftTab(focusedDay: _focusedDay, onFocus: (d) => setState(() => _focusedDay = d)),
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
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                Text('Month', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, color: cs.primary),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.focusedDay, required this.onFocus});

  final DateTime focusedDay;
  final ValueChanged<DateTime> onFocus;

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
              _counter('Present', '0', Colors.green),
              const SizedBox(width: 10),
              _counter('Absent', '0', Colors.red),
              const SizedBox(width: 10),
              _counter('Pending', '0', Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _counter('Leave', '0', Colors.orange),
              const SizedBox(width: 10),
              _counter('Holiday', '0', Colors.amber),
              const SizedBox(width: 10),
              _counter('Weekly Off', '0', Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  focusedDay: focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  headerVisible: false,
                  calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                  onPageChanged: onFocus,
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
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                Text('Month', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, color: cs.primary),
              ],
            ),
          )
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
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ShiftTab extends StatelessWidget {
  const _ShiftTab({required this.focusedDay, required this.onFocus});

  final DateTime focusedDay;
  final ValueChanged<DateTime> onFocus;

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
                child: TableCalendar(
                  focusedDay: focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  headerVisible: false,
                  calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                  onPageChanged: onFocus,
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
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                Text('Month', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, color: cs.primary),
              ],
            ),
          )
        ],
      ),
    );
  }
}
