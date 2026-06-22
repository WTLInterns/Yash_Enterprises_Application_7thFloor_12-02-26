import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/config/app_config.dart';
import 'providers/expense_providers.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static final DateFormat _time12h = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);
  }

  String _formatDateTime(String date, String time) {
    final d = date.trim();
    final t = time.trim();
    if (d.isEmpty && t.isEmpty) return '-';
    if (t.isEmpty) return d.isEmpty ? '-' : d;

    final hhmm = t.split('.').first; // 13:04:45.872 -> 13:04:45
    final parts = hhmm.split(':');
    if (parts.length < 2) return d.isEmpty ? t : '$d $t';

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return d.isEmpty ? t : '$d $t';

    final dt = DateTime(2000, 1, 1, hour, minute);
    final formattedTime = _time12h.format(dt);
    if (d.isEmpty) return formattedTime;
    return '$d $formattedTime';
  }

  String _normalizeStatus(String status) {
    final s = status.trim().toUpperCase();
    if (s.contains('APPROVE')) return 'APPROVED';
    if (s.contains('REJECT')) return 'REJECTED';
    if (s.contains('PAID')) return 'PAID';
    if (s.isEmpty) return 'PENDING';
    return s;
  }

  Color _statusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PAID':
        return Colors.blue;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  Widget _statusBadge(String status) {
    final normalized = _normalizeStatus(status);
    final color = _statusColor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Expense')),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Expense')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addExpense),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );

                    if (picked != null) {
                      ref.read(selectedMonthProvider.notifier).state = picked;
                      // Refresh expenses with new month
                      ref.refresh(expensesProvider);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Month'),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            expensesAsync.when(
              loading: () => const SizedBox(
                height: 70,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox.shrink(),
              data: (items) {
                int pending = 0;
                int approved = 0;
                int rejected = 0;
                int paid = 0;
                for (final e in items) {
                  final m = e is Map
                      ? Map<String, dynamic>.from(e as Map)
                      : <String, dynamic>{};
                  final s = (m['status'] ?? '').toString().toLowerCase();
                  if (s.contains('approve')) {
                    approved++;
                  } else if (s.contains('reject')) {
                    rejected++;
                  } else if (s.contains('paid')) {
                    paid++;
                  } else {
                    pending++;
                  }
                }

                return Row(
                  children: [
                    _counter('Pending', '$pending', Colors.orange),
                    const SizedBox(width: 10),
                    _counter('Approved', '$approved', Colors.green),
                    const SizedBox(width: 10),
                    _counter('Rejected', '$rejected', Colors.red),
                    const SizedBox(width: 10),
                    _counter('Paid out', '$paid', Colors.blue),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  expensesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        const Center(child: Text('Failed to load')),
                    data: (items) {
                      if (items.isEmpty) return const _EmptyState();

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final raw = items[i];
                          final m = raw is Map
                              ? Map<String, dynamic>.from(raw as Map)
                              : <String, dynamic>{};
                          final category = (m['category'] ?? 'Expense')
                              .toString();
                          final desc = (m['description'] ?? '').toString();
                          final date = (m['expenseDate'] ?? '').toString();
                          final time = (m['expenseTime'] ?? '').toString();
                          final amount = (m['amount'] ?? 0).toDouble();
                          final status = (m['status'] ?? 'Pending').toString();
                          final employeeName = (m['employeeName'] ?? '')
                              .toString();
                          final departmentName = (m['departmentName'] ?? '')
                              .toString();
                          final clientName = (m['clientName'] ?? '')
                              .toString()
                              .trim();
                          final receiptUrl = (m['receiptUrl'] ?? '').toString();

                          final displayDateTime = _formatDateTime(date, time);
                          final safeEmployeeName = employeeName.trim().isEmpty
                              ? 'Unknown Employee'
                              : employeeName.trim();

                          return _ElevatedExpenseCard(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Category + Status
                                  Row(
                                    children: [
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Spacer(),
                                      _statusBadge(status),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  /// Employee + Department
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          safeEmployeeName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (clientName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.business, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            clientName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black.withOpacity(
                                                0.65,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  /// Description
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.65),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),

                                  /// Date + Time
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          displayDateTime,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Amount
                                  Text(
                                    '₹ ${amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  /// Evidence Image/File
                                  if (receiptUrl.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  Navigator.of(context).pop(),
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                  "${AppConfig.apiBaseUrl}$receiptUrl",
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          "${AppConfig.apiBaseUrl}$receiptUrl",
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return const SizedBox(
                                                  height: 120,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  height: 120,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _ElevatedExpenseCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ElevatedExpenseCard({required this.child, this.onTap});

  @override
  State<_ElevatedExpenseCard> createState() => _ElevatedExpenseCardState();
}

class _ElevatedExpenseCardState extends State<_ElevatedExpenseCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));

    return AnimatedScale(
      scale: _pressed ? 0.99 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onTapDown: (_) {
          if (!_pressed) setState(() => _pressed = true);
        },
        onTapCancel: () {
          if (_pressed) setState(() => _pressed = false);
        },
        onTapUp: (_) {
          if (_pressed) setState(() => _pressed = false);
        },
        child: Material(
          elevation: 6,
          shadowColor: Colors.transparent,
          borderRadius: radius,
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF9FAFB)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(borderRadius: radius, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.inbox_outlined, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'List is Empty',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
