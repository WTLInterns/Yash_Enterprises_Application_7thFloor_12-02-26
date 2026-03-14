import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../../task/presentation/task_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../client/presentation/client_screen.dart';
import '../../expense/presentation/expense_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    DashboardScreen(),
    ClientScreen(),
    ExpenseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _navItem(
                  cs,
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                ),
                _navItem(
                  cs,
                  index: 1,
                  label: 'Attendance',
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                ),
                _navItem(
                  cs,
                  index: 2,
                  label: 'Client',
                  icon: Icons.business_outlined,
                  activeIcon: Icons.business,
                ),
                _navItem(
                  cs,
                  index: 3,
                  label: 'Expense',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    ColorScheme cs, {
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final active = _index == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: active ? 14 : 0,
              vertical: 10,
            ),
            decoration: active
                ? BoxDecoration(
                    color: cs.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? cs.primary : Colors.black.withOpacity(0.55),
                  size: 22,
                ),
                if (active) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
